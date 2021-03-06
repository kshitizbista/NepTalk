//
//  ChatViewController.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2021-12-16.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import AVKit
import CoreLocation

class ChatViewController: MessagesViewController {
    
    public var isNewConversation = false
    private let receipentUser: UserResult
    private let conversationId: String?
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = AuthManager.shared.getCurrentUser()?.email,
              let senderName = UserDefaults.standard.value(forKey: K.UserDefaultsKey.profileName) as? String else {
                  return nil
              }
        return Sender(senderId:email, displayName: senderName, photoURL: "")
    }
    private var senderPhotoUrl: URL?
    private var receiverPhotoUrl: URL?
    private var isFirstLoad = true
    
    init(with: UserResult, id: String?) {
        receipentUser = with
        conversationId = id
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
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listernForMessages(id: conversationId)
        }
    }
    
    private func setUpInputBar(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo", message: "What would you like to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController()
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let self = self,
                  let selfSender = self.selfSender,
                  let conversationId = self.conversationId else
                  {
                      return
                  }
            let longitude: Double = selectedCoordinates.longitude
            let latitidue: Double = selectedCoordinates.latitude
            let location = Location(location: CLLocation(latitude: latitidue, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: self.createMessageId(), sentDate: Date(), kind: .location(location))
            DatabaseManager.shared.sendMessage(to: conversationId, receiver: self.receipentUser, message: message) { success in
                if success {
                    print("sent location message")
                } else {
                    print("failed to send photo message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
        }))
        present(actionSheet, animated: true)
    }
    
    private func listernForMessages(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                guard let self = self,
                      !messages.isEmpty else {
                          return
                      }
                self.messages = messages
                DispatchQueue.main.async {
                    if self.isFirstLoad {
                        self.isFirstLoad = false
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: self.messages.count - 1), at: .top, animated: false)
                    } else {
                        self.isFirstLoad = false
                        self.messagesCollectionView.reloadDataAndKeepOffset()
                    }
                }
            case.failure(let error):
                print("Failed to get messages:\(error)")
            }
        }
    }
    
    private func createMessageId() -> String {
        let receiverUID = receipentUser.uid
        let currentUserUID = AuthManager.shared.getCurrentUser()!.uid
        let dateString = Date.formatToString(using: .en_US_POSIX, from: Date())
        let newIdentifier = "\(receiverUID)_\(currentUserUID)_\(dateString)"
        return newIdentifier
    }
    
    deinit {
        DatabaseManager.shared.removeMessagesListener()
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return UIColor(named: K.BrandColor.blue)!
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            if let senderPhotoUrl = senderPhotoUrl {
                avatarView.sd_setImage(with: senderPhotoUrl)
            } else {
                let uid = AuthManager.shared.getCurrentUser()!.uid
                let path = "images/\(uid)_profile_pic.png"
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case.failure(let error):
                        print(error)
                    }
                }
            }
        } else {
            if let receiverPhotoUrl = receiverPhotoUrl {
                avatarView.sd_setImage(with: receiverPhotoUrl)
            } else {
                let uid = receipentUser.uid
                let path = "images/\(uid)_profile_pic.png"
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.receiverPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case.failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = selfSender else {
            return
        }
        // send message
        let message = Message(sender: selfSender, messageId: createMessageId(), sentDate: Date(), kind: .text(text))
        if isNewConversation {
            //create convo in database
            DatabaseManager.shared.createConversation(with: receipentUser, message: message) { [weak self] result in
                switch result {
                case .success(let conversationId):
                    print("message sent")
                    self?.isNewConversation = false
                    self?.isFirstLoad = true
                    self?.listernForMessages(id: conversationId)
                    self?.messageInputBar.inputTextView.text = nil
                case .failure(let error):
                    print("failed to send message \(error)")
                }
            }
        } else {
            // append to existing conversation data
            guard let conversationId = conversationId else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, receiver: receipentUser, message: message) { [weak self] success in
                if success {
                    print("message sent")
                    self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("failed to send")
                }
            }
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let conversationId = conversationId,
              let selfSender = selfSender else {
                  return
              }
        if let image = info[.editedImage] as? UIImage,
           let imageData = image.pngData() {
            let fileName = "photo_message_\(createMessageId().replacingOccurrences(of: " ", with: "-")).png"
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let urlString):
                    if let url = URL(string: urlString),
                       let placeholder = UIImage(systemName: "photo") {
                        
                        let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                        let message = Message(sender: selfSender, messageId: self.createMessageId(), sentDate: Date(), kind: .photo(media))
                        
                        DatabaseManager.shared.sendMessage(to: conversationId, receiver: self.receipentUser, message: message) { success in
                            if success {
                                print("message sent")
                            } else {
                                print("failed to send")
                            }
                        }
                    }
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            }
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_\(createMessageId().replacingOccurrences(of: " ", with: "-")).mov"
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let urlString):
                    if let url = URL(string: urlString),
                       let placeholder = UIImage(systemName: "video") {
                        
                        let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                        let message = Message(sender: selfSender, messageId: self.createMessageId(), sentDate: Date(), kind: .video(media))
                        
                        DatabaseManager.shared.sendMessage(to: conversationId, receiver: self.receipentUser, message: message) { success in
                            if success {
                                print("message sent")
                            } else {
                                print("failed to send")
                            }
                        }
                    }
                case .failure(let error):
                    print("message video upload error: \(error)")
                }
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true) {
                vc.player?.play()
            }
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationItem):
            let coordinates = locationItem.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
            break
        default:
            break
        }
    }
}
