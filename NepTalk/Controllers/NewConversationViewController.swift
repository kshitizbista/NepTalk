//
//  NewConversationViewController.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-15.
//

import UIKit
import JGProgressHUD
import Combine

class NewConversationViewController: UIViewController {
    
    let selectUser = PassthroughSubject<UserResult, Never>()
    private let spinner = JGProgressHUD(style: .dark)
    private let newConversationViewModel = NewConversationViewModel()
    private var cancellable: AnyCancellable?
    private let search = PassthroughSubject<String, Never>()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(NewConversationTableViewCell.self, forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        return table
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(noResultLabel)
        tableView.dataSource = self
        tableView.delegate = self
        view.backgroundColor = .systemBackground
        navigationItem.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        newConversationViewModel.bind(search.eraseToAnyPublisher())
        cancellable = newConversationViewModel
            .$searchResult
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchResult in
                guard let self = self else { return }
                self.spinner.dismiss()
                if searchResult.isEmpty {
                    self.noResultLabel.isHidden = false
                    self.tableView.isHidden = true
                } else {
                    self.noResultLabel.isHidden = true
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                }
            }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width / 4 , y: (view.height - 200)/2, width: view.width/2, height: 200)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newConversationViewModel.getSearchResultCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = newConversationViewModel.searchResult[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.identifier, for: indexPath) as! NewConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedUser = newConversationViewModel.searchResult[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.selectUser.send(selectedUser)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text?.replacingOccurrences(of: " ", with: "") , !text.isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        spinner.show(in: view)
        search.send(text)
    }
}
