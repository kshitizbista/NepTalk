//
//  Extension.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-28.
//

import Foundation
import UIKit
import MessageKit
import FirebaseAuth

extension UIView {
    
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
        return frame.size.height
    }
    
    public var top: CGFloat {
        return frame.origin.y
    }
    
    public var bottom: CGFloat {
        return frame.size.height + frame.origin.y
    }
    
    public var left: CGFloat {
        return frame.origin.x
    }
    
    public var right: CGFloat {
        return frame.origin.x + frame.size.width
    }
}

extension MessageKind {
    var string: String {
        switch self {
        case .text(_):
            return K.MessageKindString.text
        case .attributedText(_):
            return K.MessageKindString.attributedText
        case .photo(_):
            return K.MessageKindString.photo
        case .video(_):
            return K.MessageKindString.video
        case .location(_):
            return K.MessageKindString.locationItem
        case .emoji(_):
            return K.MessageKindString.emoji
        case .audio(_):
            return K.MessageKindString.audioItem
        case .contact(_):
            return K.MessageKindString.contactItem
        case .linkPreview(_):
            return K.MessageKindString.linkItem
        case .custom(_):
            return K.MessageKindString.custom
        }
    }
}

extension DateFormatter {
    static let en_US_POSIX: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}


extension Date {
    static func formatToString(using formatter: DateFormatter, from date: Date) -> String {
        return formatter.string(from: date)
    }
}


extension Message {
    var string: String {
        switch self.kind {
        case .text(let textMessage):
            return textMessage
        case .attributedText(_):
            return ""
        case .photo(let mediaItem):
            return mediaItem.url!.absoluteString
        case .video(let mediaItem):
            return mediaItem.url!.absoluteString
        case .location(let locationItem):
            let location = locationItem.location
            return "\(location.coordinate.longitude),\(location.coordinate.latitude)"
        case .emoji(_):
            return ""
        case .audio(_):
            return ""
        case .contact(_):
            return ""
        case .linkPreview(_):
            return ""
        case .custom(_):
            return ""
        }
    }
}


extension AuthErrorCode: Error {
    var localizedDescription: String {
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account"
        case .userNotFound:
            return "Account not found for the specified user. Please check and try again"
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Please enter a valid email"
        case .networkError:
            return "Network error. Please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
        case .wrongPassword:
            return "Your password is incorrect. Please try again or use 'Forgot password' to reset your password"
        default:
            return "Unknown error occurred"
        }
    }
}

extension UIViewController{
    func handleError(message: String? = "Unknown error occurred") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
