//
//  ProfileViewController.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-15.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import SDWebImage

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        data.append(ProfileViewModel(type: .info, title: "Name: \(UserDefaults.standard.value(forKey: K.UserDefaultsKey.profileName) ?? "No Name")"))
        data.append(ProfileViewModel(type: .info, title: "Email: \(DatabaseManager.shared.getCurrentUser()?.email ?? "No Email")"))
        data.append(ProfileViewModel(type: .logout, title: "Log Out", handler: { [weak self] in
            guard let self = self else { return }
            let actionSheet = UIAlertController(title: "Do you want to log out ?", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                UserDefaults.standard.set(nil, forKey: K.UserDefaultsKey.profileName)
                UserDefaults.standard.set(nil, forKey: K.UserDefaultsKey.profilePictureUrl)
                FBSDKLoginKit.LoginManager().logOut()
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Failed to log out")
                    print(error)
                }
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(with: "LoginNavigationController")
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(actionSheet, animated: true)
        }))
        tableView.tableHeaderView = createTableHeader()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func createTableHeader() -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 300))
        headerView.backgroundColor = UIColor(named: K.BrandColor.blue)
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150)/2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        let uid = DatabaseManager.shared.getCurrentUser()!.uid
        let path = "images/\(uid)_profile_pic.png"
        StorageManager.shared.downloadURL(for: path) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    imageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get download url:\(error)")
            }
        }
        
        return headerView
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.configure(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
}
