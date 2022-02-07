//
//  ViewController.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-15.
//

import UIKit
import Combine

class ConversationsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    private let viewModal = ConversationViewModal()
    private var conversationSubscription: AnyCancellable?
    private var newConversationSubscription = Set<AnyCancellable>()
    private var deleteConversationSubscription: AnyCancellable?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tableView
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversation!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        tableView.delegate = self
        tableView.dataSource = self
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: 10, y: (view.height-100)/2, width: view.width - 20, height: 100)
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        newConversationSubscription.removeAll()
        vc
            .selectUser
            .sink { [unowned self] selectedUser in
                self.goToConversation(selectedUser)
            }
            .store(in: &newConversationSubscription)
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func startListeningForConversations() {
        conversationSubscription = viewModal
            .conversationsPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(_):
                    self?.tableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                }
            }, receiveValue: { [weak self] conversations in
                if !conversations.isEmpty {
                    self?.tableView.isHidden = false
                    self?.noConversationLabel.isHidden = true
                    self?.conversations = conversations
                    self?.tableView.reloadData()
                }
                else {
                    self?.tableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                }
            })
    }
    
    private func goToConversation(_ selectedUser: UserResult) {
        if let targetConversation = conversations.first(where: {$0.receiverUID == selectedUser.uid}) {
            let vc = ChatViewController(with: selectedUser, id: targetConversation.id)
            vc.isNewConversation = false
            vc.title = targetConversation.receiverName
            vc.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(vc, animated: false)
        } else {
            viewModal
                .conversationIDPublisher(userResult: selectedUser)
                .sink { [unowned self] completion in
                    switch completion {
                    case .finished: break
                    case .failure(_):
                        let vc = ChatViewController(with: selectedUser, id: nil)
                        vc.isNewConversation = true
                        vc.title = selectedUser.name
                        vc.navigationItem.largeTitleDisplayMode = .never
                        self.navigationController?.pushViewController(vc, animated: false)
                    }
                } receiveValue: { conversationId in
                    let vc = ChatViewController(with: selectedUser, id: conversationId)
                    vc.isNewConversation = false
                    vc.title = selectedUser.name
                    vc.navigationItem.largeTitleDisplayMode = .never
                    self.navigationController?.pushViewController(vc, animated: false)
                }
                .store(in: &newConversationSubscription)
        }
    }
    
    deinit {
        viewModal.detachConverstionsListener()
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            deleteConversationSubscription?.cancel()
            deleteConversationSubscription = viewModal
                .deleteConversationPublisher(conversationId: conversationId)
                .first()
                .sink { success in
                    print("Conversation deleted")
                }
            //            Dont need to manually delete because we are listening to the changes in startListeningForConversations func
            //            tableView.beginUpdates()
            //            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
            //                if success {
            //                    guard let self = self else { return }
            //                    self.conversations.remove(at: indexPath.row)
            //                    tableView.deleteRows(at: [indexPath], with: .left)
            //                }
            //            }
            //            tableView.endUpdates()
        }
    }
    
    func openConversation(_ model: Conversation) {
        let userResult = UserResult(uid: model.receiverUID, email: model.receiverEmail, name: model.receiverName)
        let vc = ChatViewController(with:userResult, id: model.id)
        vc.title = model.receiverName
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}
