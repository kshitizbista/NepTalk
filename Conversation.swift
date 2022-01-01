//
//  Conversation.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-01.
//

import Foundation

struct Conversation {
    let id: String
    let receiverName: String
    let receiverEmail: String
    let receiverUID: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let message: String
    let isRead: Bool
}

struct UserResult {
    let uid: String
    let email: String
    let name: String
}
