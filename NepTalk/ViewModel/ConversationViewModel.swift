//
//  ConversationViewModel.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-19.
//

import Foundation
import Combine

final class ConversationViewModal {
    
    private var conversationsSubject = PassthroughSubject<[Conversation], Error>()
    private var conversationIDSubject = PassthroughSubject<String, Error>()
    private var conversationDeletionSubject = PassthroughSubject<Bool, Never>()
    
    func conversationsPublisher() -> AnyPublisher<[Conversation], Error> {
        DatabaseManager.shared.getAllConversations{ [weak self] result in
            switch result {
            case .success(let conversations):
                self?.conversationsSubject.send(conversations)
            case .failure(let error):
                self?.conversationsSubject.send(completion: .failure(error))
            }
        }
        return conversationsSubject.eraseToAnyPublisher()
    }
    
    func conversationIDPublisher(userResult: UserResult) -> AnyPublisher<String, Error> {
        DatabaseManager.shared.conversationExists(with: userResult.uid) { [weak self] result in
            switch result {
            case .success(let conversationId):
                self?.conversationIDSubject.send(conversationId)
                
            case .failure(let error):
                self?.conversationIDSubject.send(completion: .failure(error))
            }
        }
        return conversationIDSubject.eraseToAnyPublisher()
    }
    
    func deleteConversationPublisher(conversationId: String) -> AnyPublisher<Bool, Never> {
        DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
            if success {
                self?.conversationDeletionSubject.send(true)
            } else {
                self?.conversationDeletionSubject.send(false)
            }
        }
        return conversationDeletionSubject.eraseToAnyPublisher()
    }
    
    func detachConverstionsListener() {
        DatabaseManager.shared.removeConverstionsListener()
    }
}
