//
//  ChatViewController.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2021-12-16.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

extension MessageKind {
    var string: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "media_item"
        case .location(_):
            return "location_item"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio_item"
        case .contact(_):
            return "contact_item"
        case .linkPreview(_):
            return "link_item"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
    var photoURL: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    public var isNewConversation = false
    private let receipentUser: UserResult
    private let conversationId: String?
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = DatabaseManager.shared.getCurrentUser()?.email,
              let senderName = UserDefaults.standard.value(forKey: "name") as? String else {
                  return nil
              }
        return Sender(senderId:email, displayName: senderName, photoURL: "")
    }
    
    init(with: UserResult, id: String?) {
        self.receipentUser = with
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listernForMessages(id: conversationId, shouldScrollToBottom: false)
        }
    }
    
    private func listernForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case.failure(let error):
                print("Failed to get messages:\(error)")
            }
        }
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = selfSender, let messageId = createMessageId() else {
            return
        }
        // send message
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            //create convo in database
            DatabaseManager.shared.createConversation(with: receipentUser.email, receiverUID: receipentUser.uid, receiverName: receipentUser.name, message: message) { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                } else {
                    print("failed to send message")
                }
            }
        } else {
            // append to existing conversation data
            guard let conversationId = conversationId else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, message: message) { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        let receiverUID = receipentUser.uid
        let currentUserUID = DatabaseManager.shared.getCurrentUser()!.uid
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(receiverUID)_\(currentUserUID)_\(dateString)"
        return newIdentifier
    }
}
