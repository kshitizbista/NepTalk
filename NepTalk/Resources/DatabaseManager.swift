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
    
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func getCurrentUser() -> User? {
        return FirebaseAuth.Auth.auth().currentUser
    }
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        database.child("users")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: email.lowercased())
            .observeSingleEvent(of: .value) { snapshot in
                if ((snapshot.value as? NSDictionary) != nil)  {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }
    
    /// Inserts new user to databse
    public func insertUser (with user: AppUser, completion: @escaping (Bool) -> Void) {
        database.child("users/\(user.uid)").setValue(["firstName": user.firstName, "lastName": user.lastName, "email": user.email]) { error, _ in
            if error == nil  {
                completion(true)
            } else {
                print("failed to write to database")
                completion(false)
            }
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
