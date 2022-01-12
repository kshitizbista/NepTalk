//
//  NewConversationCell.swift
//  NepTalk
//
//  Created by Kshitiz Bista on 2022-01-04.
//

import Foundation
import SDWebImage

final class NewConversationTableViewCell: UITableViewCell {
    
    static let identifier = "NewConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        return imageView;
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 60, height: 60)
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 20, width: contentView.width - 20 - userImageView.width, height: 40)
    }
    
    public func configure(with model: UserResult) {
        userNameLabel.text = model.name
        let path = "images/\(model.uid)_profile_pic.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image url: \(error)")
            }
        }
    }
}
