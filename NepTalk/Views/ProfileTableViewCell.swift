//
//  ProfileTableViewCell.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-09.
//

import UIKit

final class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableviewCell"
    
    public func configure(with viewModal: ProfileViewModel) {
        textLabel?.text = viewModal.title
        switch viewModal.type {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .systemRed
            textLabel?.textAlignment = .center
        }
    }
}
