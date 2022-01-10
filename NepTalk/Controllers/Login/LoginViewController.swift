//
//  LoginViewController.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-15.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView: UIScrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: K.logoName)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor(named: K.BrandColor.blue)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action:#selector(registerButtonTapped))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        
        // Add subsviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
        googleLoginButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        facebookLoginButton.frame = CGRect(x: 30, y: googleLoginButton.bottom + 10, width: scrollView.width - 60, height: 28)
    }
    
    @objc private func registerButtonTapped() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty else {
                  alertUserLoginError(message: "Please enter all information to log in")
                  return
              }
        
        spinner.show(in: view)
        
        // Firebase login
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            if authResult == nil, let error = error  {
                self.alertUserLoginError(message: error.localizedDescription)
                return
            }
            DatabaseManager.shared.getDataFor(path: authResult!.user.uid) { result in
                switch result {
                case .success(let data):
                    if let userData = data as? [String: Any]  {
                        let firstName = (userData["firstName"] as? String) ?? ""
                        let lastName = (userData["lastName"] as? String) ?? ""
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.UserDefaultsKey.profileName)
                    }
                case .failure(let error):
                    print("Failed toread data with error \(error)")
                }
            }
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(with: "MainTabBarController")
        }
    }
    
    private func alertUserLoginError(title: String? = "Login Error", message: String? = "Something went wrong")  {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - TextFields Focus Handler
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

// MARK: - Facebook Login Handler
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            alertUserLoginError(message: error.localizedDescription)
        } else {
            guard let token = result?.token?.tokenString else { return }
            let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email,first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
            facebookRequest.start { [weak self] _, fbResult, error in
                guard let self = self else { return }
                
                guard let fbResult = fbResult as? [String: Any], error == nil else {
                    self.alertUserLoginError(message: "Failed to retrieve data from facebook")
                    return
                }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: token)
                self.spinner.show(in: self.view)
                Auth.auth().signIn(with: credential) { authResult, error in
                    guard let authResult = authResult , error == nil else {
                        self.alertUserLoginError(message: error?.localizedDescription)
                        return
                    }
                    if let email = fbResult["email"] as? String {
                        let firstName = (fbResult["first_name"] as? String) ?? ""
                        let lastName = (fbResult["last_name"] as? String) ?? ""
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.UserDefaultsKey.profileName)
                        DatabaseManager.shared.userExists(with: authResult.user.uid) { exists in
                            let appUser = AppUser(uid: authResult.user.uid,firstName: firstName, lastName: lastName, email: email)
                            if !exists {
                                DatabaseManager.shared.insertUser(with: appUser) { success in
                                    if success, let picture = fbResult["picture"] as? [String: Any],
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
                                                    UserDefaults.standard.set(downloadUrl, forKey: K.UserDefaultsKey.profilePictureUrl)
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
                    DispatchQueue.main.async {
                        self.spinner.dismiss()
                    }
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(with: "MainTabBarController")
                }
            }
        }
    }
}

// MARK: - GoogleSignIn Handler
extension LoginViewController {
    
    @objc private func googleSignInButtonTapped() {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {return}
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            guard let self = self else { return }
            if let error = error {
                self.alertUserLoginError(message: error.localizedDescription)
            } else {
                guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                    self.alertUserLoginError(message: "Failed to retrieve data from Google")
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                self.spinner.show(in: self.view)
                Auth.auth().signIn(with: credential) { authResult, error in
                    guard let authResult = authResult , error == nil else {
                        self.alertUserLoginError(message: error?.localizedDescription)
                        return
                    }
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
                                                    UserDefaults.standard.set(downloadUrl, forKey: K.UserDefaultsKey.profilePictureUrl)
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
                    DispatchQueue.main.async {
                        self.spinner.dismiss()
                    }
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(with: "MainTabBarController")
                }
            }
        }
    }
}
