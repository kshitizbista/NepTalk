//
//  Extension.swift
//  ios-chat-app
//
//  Created by Kshitiz Bista on 2021-11-28.
//

import Foundation
import UIKit
import MessageKit

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
