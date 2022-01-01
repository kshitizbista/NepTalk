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
                        "email": user.email,
                        "uid": user.uid
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
                            "email": user.email,
                            "uid": user.uid
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
    
    public func getAllUsers(completion: @escaping (Result<[UserResult], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let searchResult: [UserResult] = value.compactMap { dictionary in
                guard let email = dictionary["email"],
                      let name = dictionary["name"] ,
                      let uid = dictionary["uid"] else {
                          return nil
                      }
                return UserResult(uid: uid, email: email, name: name)
            }
            
            completion(.success(searchResult))
        }
    }
}

// MARK: - Message Handler
extension DatabaseManager {
    
    /// Create a new conversation with target user email
    public func createConversation(with receiverEmail: String, receiverUID: String, receiverName: String, message: Message, completion: @escaping (Bool) -> Void) {
        guard let senderEmail = getCurrentUser()?.email,
              let senderUID = getCurrentUser()?.uid,
              let senderName = UserDefaults.standard.value(forKey: "name") as? String else {
                  return
              }
        let senderRef = database.child("\(senderUID)/conversations")
        let receiverRef = database.child("\(receiverUID)/conversations")
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
        let senderConversation: [String: Any] = [
            "id": conversationId,
            "receiver_email": receiverEmail,
            "receiver_uid": receiverUID,
            "receiver_name": receiverName,
            "latest_message": [
                "date": dateString,
                "message": newMessage,
                "is_read": false
            ]
        ]
        
        let receiverConversation: [String: Any] = [
            "id": conversationId,
            "receiver_email": senderEmail,
            "receiver_uid": senderUID,
            "receiver_name": senderName,
            "latest_message": [
                "date": dateString,
                "message": newMessage,
                "is_read": false
            ]
        ]
        
        senderRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            receiverRef.observeSingleEvent(of: .value) { snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    conversations.append(receiverConversation)
                    receiverRef.setValue(conversations)
                } else {
                    receiverRef.setValue([receiverConversation])
                }
            }
            if var value = snapshot.value as? [[String: Any]] {
                value.append(senderConversation)
                senderRef.setValue(value) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self.addConversation(conversationId: conversationId, senderEmail: senderEmail, senderName: senderName, message: message, completion: completion)
                }
            } else {
                senderRef.setValue([senderConversation]) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self.addConversation(conversationId: conversationId, senderEmail: senderEmail, senderName: senderName, message: message, completion: completion)
                }
            }
        }
    }
    
    /// Fetch and return all convsersation for the user with passed in email
    public func getAllConversations(completion: @escaping (Result<[Conversation], Error>) -> Void) {
        guard let uid = getCurrentUser()?.uid else {
            return
        }
        database.child("\(uid)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let receiverName = dictionary["receiver_name"] as? String,
                      let receiverEmail = dictionary["receiver_email"] as? String,
                      let receiverUID = dictionary["receiver_uid"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                          return nil
                      }
                let latestMessageObject = LatestMessage(date: date, message: message, isRead: isRead)
                return Conversation(id: conversationId, receiverName: receiverName, receiverEmail: receiverEmail, receiverUID: receiverUID, latestMessage: latestMessageObject)
            }
            completion(.success(conversations))
        }
    }
    
    /// Get all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap { dictionary in
                guard let senderName = dictionary["sender_name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"],
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                          return nil
                      }
                let sender = Sender(senderId: senderEmail, displayName: senderName, photoURL: "")
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
            }
            completion(.success(messages))
        }
    }
    
    /// Send a message with target conversation and message
    public func sendMessage(to conversationId: String, receiverUID: String, message: Message, completion: @escaping (Bool) -> Void) {
        //add new message to messages
        // update sender latest message
        // update recepient latest message
        
        guard let senderEmail = getCurrentUser()?.email,
              let senderUID = getCurrentUser()?.uid,
              let senderName = UserDefaults.standard.value(forKey: "name") as? String else {
                  return
              }
        
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
        
        let messageEntry: [String: Any] = [
            "id": message.messageId,
            "type": message.kind.string,
            "content": newMessage,
            "date": dateString,
            "sender_email": senderEmail,
            "sender_name": senderName,
            "is_read": false
        ]
        
        let latestMessage: [String: Any] = [
            "date": dateString,
            "message": newMessage,
            "is_read": false
        ]
        
        let ref = database.child("\(conversationId)/messages")
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self,
                  var currentMessage = snapshot.value as? [[String: Any]] else {
                      completion(false)
                      return
                  }
            currentMessage.append(messageEntry)
            ref.setValue(currentMessage) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                let senderNodeRef = self.database.child("\(senderUID)/conversations")
                let receiverNodeRef = self.database.child("\(receiverUID)/conversations")
                
                senderNodeRef.observeSingleEvent(of: .value) { snapshot in
                    guard var value = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    if let row = value.firstIndex(where: {$0["id"] as? String == conversationId}) {
                        value[row]["latest_message"] = latestMessage
                        senderNodeRef.setValue(value) { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            
                            receiverNodeRef.observeSingleEvent(of: .value) { snapshot in
                                guard var value = snapshot.value as? [[String: Any]] else {
                                    completion(false)
                                    return
                                }
                                
                                if let row = value.firstIndex(where: {$0["id"] as? String == conversationId}) {
                                    value[row]["latest_message"] = latestMessage
                                    receiverNodeRef.setValue(value) { error, _ in
                                        guard error == nil else {
                                            completion(false)
                                            return
                                        }
                                        completion(true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child(path).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    private func addConversation(conversationId: String, senderEmail: String, senderName: String, message: Message, completion: @escaping (Bool) -> Void ) {
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
        
        let collectionMessage: [String: Any] = [
            "id": message.messageId,
            "type": message.kind.string,
            "content": newMessage,
            "date": dateString,
            "sender_email": senderEmail,
            "sender_name": senderName,
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
