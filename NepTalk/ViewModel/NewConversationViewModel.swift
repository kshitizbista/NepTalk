//
//  NewConversationViewModel.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-17.
//

import Foundation
import Combine

final class NewConversationViewModel {
    
    @Published private(set) var searchResult = [UserResult]()
    private var users = [UserResult]()
    private var cancellable: AnyCancellable?
    
    func bind(_ query: AnyPublisher<String, Never>) {
        cancellable = query
            .sink { [weak self] searchQuery in
            guard let self = self else { return }
            var hasFetched = false
            if hasFetched {
                // if it does: filter
                self.filterUsers(with: searchQuery)
            } else {
                // if not, fetch then filter
                DatabaseManager.shared.getAllUsers { result in
                    switch result {
                    case .success(let userCollection):
                        hasFetched = true
                        self.users = userCollection
                        self.filterUsers(with: searchQuery)
                    case .failure(let error):
                        print("Failed to get users: \(error)")
                    }
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
        searchResult = results
    }
}
