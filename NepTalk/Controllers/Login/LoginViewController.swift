//
//  LoginViewController.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-15.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private let loginViewModel = LoginViewModel()
    
    private let scrollView: UIScrollView = {
        let scrollView: UIScrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: K.logoName)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor(named: K.BrandColor.blue)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action:#selector(registerButtonTapped))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        loginViewModel.delegate = self
        
        // Add subsviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52)
        googleLoginButton.frame = CGRect(x: 30, y: loginButton.bottom + 10, width: scrollView.width - 60, height: 52)
        facebookLoginButton.frame = CGRect(x: 30, y: googleLoginButton.bottom + 10, width: scrollView.width - 60, height: 28)
    }
    
    @objc private func registerButtonTapped() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty else {
                  self.handleError(message: "Please enter all information to log in")
                  return
              }
        
        spinner.show(in: view)
        loginViewModel.signIn(withEmail: email, password: password)
    }
    
    @objc private func googleSignInButtonTapped() {
        spinner.show(in: view)
        loginViewModel.googleSignIn(presentingView: self)
    }
}

// MARK: - TextFields Focus Handler
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

// MARK: - Facebook Login Button Delegate
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            handleError(message: error.localizedDescription)
        } else {
            guard let token = result?.token?.tokenString else { return }
            let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email,first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
            facebookRequest.start { [weak self] _, fbResult, error in
                guard let self = self,
                      let fbResult = fbResult as? [String: Any],
                      error == nil else {
                          self?.handleError(message: "Failed to retrieve data from facebook")
                          return
                      }
                self.spinner.show(in: self.view)
                self.loginViewModel.facebookLogIn(token: token, data: fbResult)
            }
        }
    }
}

// MARK: - LoginView Delegate
extension LoginViewController: LoginViewDelegate {
    func didSignIn() {
        spinner.dismiss()
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(with: "MainTabBarController")
    }
    
    func isError(error: Error) {
        spinner.dismiss()
        handleError(message: error.localizedDescription)
    }
}
