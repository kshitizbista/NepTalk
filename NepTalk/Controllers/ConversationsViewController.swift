//
//  ViewController.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-15.
//

import UIKit
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    
    private let spinner = JGProgressHUD(style: .dark)
    
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
        fetchConversation()
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func fetchConversation() {
        tableView.isHidden = false
    }
    
    private func startListeningForConversations() {
        DatabaseManager.shared.getAllConversations{ [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let self = self else {
                return
            }
            if let targetConversation = self.conversations.first(where: {$0.receiverUID == result.uid}) {
                let vc = ChatViewController(with: result, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.receiverName
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: false)
            } else {
                self.createNewConversation(userResult: result)
            }
            
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func createNewConversation(userResult: UserResult) {
        DatabaseManager.shared.conversationExists(with: userResult.uid) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: userResult, id: conversationId)
                vc.isNewConversation = false
                vc.title = userResult.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: false)
            case .failure(_):
                let vc = ChatViewController(with: userResult, id: nil)
                vc.isNewConversation = true
                vc.title = userResult.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: false)
            }
        }
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
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] success in
                if success {
                   print("Conversation deleted")
                }
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
