//
//  ProfileViewModel.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-09.
//

import Foundation

enum ProfileType {
    case info, logout
}

struct ProfileViewModel {
    let type: ProfileType
    let title: String
    let handler: (() -> Void)?
    
    init(type: ProfileType, title: String, handler: (() -> Void)? = nil) {
        self.type = type
        self.title = title
        self.handler = handler
    }
}
