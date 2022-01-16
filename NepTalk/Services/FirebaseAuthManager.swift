//
//  FirebaseAuthManager.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-16.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthManager {
  
    public static let shared = FirebaseAuthManager()
   
    private init() {
    }
    
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func signIn(with email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void ) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, authError in
            if authResult == nil, let error = authError {
                completion(.failure(error))
                return
            }
            completion(.success(authResult!))
        }
    }
    
    func signIn(with credential: AuthCredential, completion: @escaping (Result<AuthDataResult, Error>) -> Void ) {
        Auth.auth().signIn(with: credential) { authResult, error in
            guard let authResult = authResult, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(authResult))
        }
    }
    
    func fbCredential(token: String) -> AuthCredential {
        return FacebookAuthProvider.credential(withAccessToken: token)
    }
}
