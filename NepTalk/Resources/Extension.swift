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
        return self.frame.size.width
    }
    
    public var height: CGFloat {
        return self.frame.size.height
    }
    
    public var top: CGFloat {
        return self.frame.origin.y
    }
    
    public var bottom: CGFloat {
        return self.frame.size.height + self.frame.origin.y
    }
    
    public var left: CGFloat {
        return self.frame.origin.x
    }
    
    public var right: CGFloat {
        return self.frame.origin.x + self.frame.size.width
    }
}

extension MessageKind {
    var string: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "media_item"
        case .location(_):
            return "location_item"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio_item"
        case .contact(_):
            return "contact_item"
        case .linkPreview(_):
            return "link_item"
        case .custom(_):
            return "custom"
        }
    }
}
