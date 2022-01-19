//
//  NewConversationViewModel.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-17.
//

import Foundation

protocol NewConversationViewDelegate: AnyObject {
    func shouldUpdateUI(searchResult: [UserResult]) -> Void
}

final class NewConversationViewModel {
    
    private var users = [UserResult]()
    private var hasFetched = false
    weak var delegate: NewConversationViewDelegate?
    var searchResult = [UserResult]()
    
    func searchUsers(query: String) {
        // check if array has firebase results
        if hasFetched {
            // if it does: filter
            filterUsers(with: query)
        } else {
            // if not, fetch then filter
            DatabaseManager.shared.getAllUsers { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let userCollection):
                    self.hasFetched = true
                    self.users = userCollection
                    self.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            }
        }
    }
    
    func getSearchResultCount() -> Int {
        return searchResult.count
    }
    
    func removeAllSearchResult() {
        return searchResult.removeAll()
    }
    
    private func filterUsers(with term: String) {
        let results = users.filter {
            let name = $0.name.lowercased()
            return name.hasPrefix(term.lowercased()) && $0.email.lowercased() != AuthManager.shared.getCurrentUser()!.email
        }
        self.searchResult = results
        self.delegate?.shouldUpdateUI(searchResult: results)
    }
}
