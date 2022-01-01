//
//  AppUser.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-01.
//

import Foundation

struct AppUser {
    let uid: String
    let firstName: String
    let lastName: String
    var email: String
    var profilePictureFileName: String {
        return "\(uid)_profile_pic.png"
    }
    
    init(uid: String, firstName: String, lastName: String, email: String) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}
