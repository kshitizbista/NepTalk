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
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func getuid() -> String? {
        return FirebaseAuth.Auth.auth().currentUser?.uid
    }
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
       
        database.child("users")
            .queryOrdered(byChild: "email")
            .queryEqual(toValue: email)
            .observeSingleEvent(of: .value) { snapshot in
            if ((snapshot.value as? NSDictionary) != nil)  {
                    completion(true)
            }
            else {
                completion(false)
            }
        }
    }
    
    /// Inserts new user to databse
    public func insertUser (with user: User) {
        database.child("users/\(user.uid)").setValue(["firstName": user.firstName, "lastName": user.lastName, "email": user.email])
    }
}

struct User {
    let uid: String
    let firstName: String
    let lastName: String
    let email: String
    //    let profilePictureUrl: String
}
