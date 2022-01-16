//
//  LoginViewModel.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-16.
//

import Foundation
import FBSDKLoginKit
import GoogleSignIn
import Firebase

protocol LoginViewDelegate: AnyObject {
    func didSignIn()
    func isError(error: Error)
}

final class LoginViewModel {
    
    weak var delegate: LoginViewDelegate?
    
    func signIn(withEmail email: String, password: String) {
        AuthManager.shared.signIn(with: email, password: password) { [weak self] result in
            switch result {
            case .success(let authResult):
                self?.delegate?.didSignIn()
                DatabaseManager.shared.getDataFor(path: authResult.user.uid) { result in
                    switch result {
                    case .success(let data):
                        var firstName = ""
                        var lastName = ""
                        if let userData = data as? [String: Any]  {
                            firstName = (userData["firstName"] as? String) ?? ""
                            lastName = (userData["lastName"] as? String) ?? ""
                        }
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.UserDefaultsKey.profileName)
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                self?.delegate?.isError(error: error)
            }
        }
    }
    
    func createUser(email: String, password: String, firstName: String, lastName: String, imageData: Data?) {
        AuthManager.shared.createUser(with: email, password: password) { [weak self] result in
            switch result {
            case .success(let authResult):
                self?.delegate?.didSignIn()
                UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.UserDefaultsKey.profileName)
                let user = AppUser(uid: authResult.user.uid, firstName: firstName, lastName: lastName, email: email)
                DatabaseManager.shared.insertUser(with: user) { success in
                    if success, let data = imageData {
                        let fileName = user.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: K.UserDefaultsKey.profilePictureUrl)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        }
                    }
                }
            case .failure(let error):
                self?.delegate?.isError(error: error)
            }
        }
    }
    
    func signOut() {
        FBSDKLoginKit.LoginManager().logOut()
        AuthManager.shared.signOut()
    }
}

// MARK: - Google SignIn Handler
extension LoginViewModel {
    func googleSignIn(presentingView: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {return}
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: presentingView) { [weak self] user, error in
            guard let self = self else { return }
            if let error = error {
                self.delegate?.isError(error: error)
            } else {
                guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                    self.delegate?.isError(error: DatabaseManager.DatabaseError.custom("Failed to retrieve data from Google"))
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                AuthManager.shared.signIn(with: credential) { result in
                    switch result {
                    case .success(let authResult):
                        self.delegate?.didSignIn()
                        if let userProfile = user?.profile {
                            let email = userProfile.email
                            let firstName = userProfile.givenName ?? ""
                            let lastName = userProfile.familyName ?? ""
                            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.UserDefaultsKey.profileName)
                            DatabaseManager.shared.userExists(with: authResult.user.uid) { exists in
                                if !exists {
                                    let appUser = AppUser(uid: authResult.user.uid,firstName: firstName, lastName: lastName, email: email)
                                    DatabaseManager.shared.insertUser(with: appUser) { success in
                                        if success && userProfile.hasImage {
                                            let fileName = appUser.profilePictureFileName
                                            guard let imageUrl = userProfile.imageURL(withDimension: 200) else { return }
                                            URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
                                                guard let data = data else {return}
                                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                                    switch result {
                                                    case .success(let downloadUrl):
                                                        print("Successfully downloaded url:\(downloadUrl)")
                                                    case .failure(let error):
                                                        print("Storage manager error: \(error)")
                                                    }
                                                }
                                            }.resume()
                                        }
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        self.delegate?.isError(error: error)
                    }
                }
            }
        }
    }
}

// MARK: - FaceLogin Handler
extension LoginViewModel {
    func facebookLogIn(token: String, data: [String: Any]) {
        let credential = AuthManager.shared.fbCredential(token: token)
        AuthManager.shared.signIn(with: credential) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let authResult):
                self.delegate?.didSignIn()
                if let email = data["email"] as? String {
                    let firstName = (data["first_name"] as? String) ?? ""
                    let lastName = (data["last_name"] as? String) ?? ""
                    DatabaseManager.shared.userExists(with: authResult.user.uid) { exists in
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.UserDefaultsKey.profileName)
                        if !exists {
                            let appUser = AppUser(uid: authResult.user.uid,firstName: firstName, lastName: lastName, email: email)
                            DatabaseManager.shared.insertUser(with: appUser) { success in
                                if success, let picture = data["picture"] as? [String: Any],
                                   let data = picture["data"] as? [String: Any], let pictureUrl = data["url"] as? String {
                                    guard let url = URL(string: pictureUrl) else { return }
                                    print("Downloading data from facebook image")
                                    URLSession.shared.dataTask(with: url) { data, urlResponse, error in
                                        guard let data = data else {
                                            print("Failed to get data from facebook")
                                            return
                                        }
                                        print("Got data from FB, uploading....")
                                        let fileName = appUser.profilePictureFileName
                                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                            switch result {
                                            case .success(let downloadUrl):
                                                print("Successfully downloaded url:\(downloadUrl)")
                                            case .failure(let error):
                                                print("Storage manager error: \(error)")
                                            }
                                        }
                                    }.resume()
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                self.delegate?.isError(error: error)
            }
        }
    }
}
