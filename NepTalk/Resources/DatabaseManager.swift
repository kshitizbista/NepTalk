//
//  DatabaseManager.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2021-12-02.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

final class DatabaseManager {
    
    private init() {}
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func getCurrentUser() -> User? {
        return FirebaseAuth.Auth.auth().currentUser
    }
    
    public func userExists(with uid: String, completion: @escaping ((Bool) -> Void)) {
        database.child(uid)
            .observeSingleEvent(of: .value) { snapshot in
                if ((snapshot.value as? String) != nil)  {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }
    
    /// Inserts new user to databse
    public func insertUser (with user: AppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.uid).setValue(["firstName": user.firstName, "lastName": user.lastName, "email": user.email]) { error, _ in
            guard error == nil  else {
                print("failed to write to database")
                completion(false)
                return
            }
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var userCollections = snapshot.value as? [[String: String]] {
                    let newElements = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.email
                    ]
                    userCollections.append(newElements)
                    self.database.child("users").setValue(userCollections) { error, _ in
                        guard error == nil  else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.email
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil  else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

struct AppUser {
    let uid: String
    let firstName: String
    let lastName: String
    var email: String {
        get {
            return lowerCasedEmail
        }
        set {
            lowerCasedEmail = newValue.lowercased()
        }
    }
    var profilePictureFileName: String {
        return "\(uid)_profile_pic.png"
    }
    private var lowerCasedEmail: String = ""
    
    init(uid: String, firstName: String, lastName: String, email: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}
