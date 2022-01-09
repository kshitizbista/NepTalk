//
//  ProfileTableViewCell.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-09.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableviewCell"
    
    public func configure(with viewModal: ProfileViewModel) {
        self.textLabel?.text = viewModal.title
        switch viewModal.type {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .systemRed
            self.textLabel?.textAlignment = .center
        }
    }
}
