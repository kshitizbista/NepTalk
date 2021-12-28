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
    private let userResult: UserResult
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        return Sender(senderId:email, displayName: "Joe Smith", photoURL: "")
    }
    
    init(with: UserResult) {
        self.userResult = with
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
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
        return Sender(senderId: "", displayName: "", photoURL: "")
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
        if isNewConversation {
            //create convo in database
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: userResult.email, receiverUID: userResult.uid, name: userResult.name, message: message) { success in
                if success {
                    print("message sent")
                }else {
                    print("failed to send message")
                }
            }
        } else {
            // append tp existing conversation data
        }
    }
    
    private func createMessageId() -> String? {
//        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
//            return nil
//        }
//
//        let receiverUID = DatabaseManager.safeEmail(email: userResult.email)
//        let currentUserUID = DatabaseManager.safeEmail(email: currentUserEmail)
        let receiverUID = userResult.uid
        let currentUserUID = DatabaseManager.shared.getCurrentUser()!.uid
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(receiverUID)_\(currentUserUID)_\(dateString)"
        return newIdentifier
    }
}
