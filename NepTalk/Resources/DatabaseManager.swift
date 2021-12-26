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
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
}

// MARK: - Account Management
extension DatabaseManager {
    
    public func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    public func userExists(with uid: String, completion: @escaping ((Bool) -> Void)) {
        database.child(uid)
            .observeSingleEvent(of: .value) { snapshot in
                if ((snapshot.value as? [String: Any]) != nil)  {
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
            self.database.child("users").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else { return }
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

// MARK: - Message Handler
extension DatabaseManager {
    
    
    //    "unique_identifier" {
    //        "messages": [
    //            {
    //                "id": String,
    //                "type": text, photo, video,
    //                "content": String,
    //                "date": Date(),
    //                "sender_email": String,
    //                "isRead": true/false
    //            }
    //        ]
    //    }
    
    
    //     conversation => [
    //        [
    //            "id": "unique_identifier"
    //            "receiver_email": String
    //            "latest_message": => {
    //                    "date": Date(),
    //                    "latest_message": "message",
    //                    "is_read": true/false
    //                }
    //        ]
    //     ]
    
    
    /// Create a new conversation with target user email
    public func createNewConversation(with receiverEmail: String, message: Message, completion: @escaping (Bool) -> Void) {
        guard let _ = UserDefaults.standard.value(forKey: "email") as? String, let uid = getCurrentUser()?.uid else {
            return
        }
        let ref = database.child(uid)
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            var userNode = snapshot.value as! [String: Any]
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var newMessage = ""
            switch message.kind {
            case .text(let textMessage):
                newMessage = textMessage
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(message.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "receiver_email": receiverEmail,
                "latest_message": [
                    "date": dateString,
                    "latest_message": newMessage,
                    "is_read": false
                ]
            ]
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { error, _ in
                    if error == nil {
                        self.finishCreatingConversation(conversationId: conversationId, message: message, completion: completion)
                    } else {
                        completion(false)
                    }
                }
                
            } else {
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode) { error, _ in
                    if error == nil {
                        self.finishCreatingConversation(conversationId: conversationId, message: message, completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    /// Fetche and return all convsersation for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Get all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
    
    private func finishCreatingConversation(conversationId: String, message: Message, completion: @escaping (Bool) -> Void ) {
        let messageDate = message.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var newMessage = ""
        switch message.kind {
        case .text(let textMessage):
            newMessage = textMessage
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") else {
            completion(false)
            return
        }
        
        let collectionMessage: [String: Any] = [
            "id": message.messageId,
            "type": message.kind.string,
            "content": newMessage,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        database.child(conversationId).setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
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
