//
//  Extensions.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 15/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import PKHUD
extension UIViewController {
    func showAlert(title: String, contentText: String, actions: [UIAlertAction]) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: contentText, preferredStyle: .alert)
            for action in actions {
                alertController.addAction(action)
            }
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
private var networkActivityCount = 0
extension UIApplication {
    
    func startNetworkActivity(info: String?) {
        networkActivityCount += 1
        isNetworkActivityIndicatorVisible = true
        if info != nil {
            let contentType = HUDContentType.labeledProgress(title: "Just a moment..", subtitle: info)
            HUD.show(contentType)
        }
        else {
            HUD.show(.progress)
        }
    }
    
    func stopNetworkActivity() {
        if networkActivityCount < 1 {
            return;
        }
        
        networkActivityCount -= 1
        if networkActivityCount == 0 {
            isNetworkActivityIndicatorVisible = false
            HUD.hide(animated: true)
        }
    }
}
//extension NSURL {
//    
//    typealias ImageCacheCompletion = (UIImage) -> Void
//    
//    /// Retrieves a pre-cached image, or nil if it isn't cached.
//    /// You should call this before calling fetchImage.
//    var cachedImage: UIImage? {
//        return ChatImageCache.sharedCache.object(forKey: absoluteString as AnyObject) as? UIImage
//    }
//    
//    /// Fetches the image from the network.
//    /// Stores it in the cache if successful.
//    /// Only calls completion on successful image download.
//    /// Completion is called on the main thread.
//    func fetchImage(completion: @escaping ImageCacheCompletion) {
//        let task = URLSession.shared.dataTask(with: self as URL) {
//            data, response, error in
//            if error == nil {
//                if let  data = data,
//                    let image = UIImage(data: data) {
//                    ChatImageCache.sharedCache.setObject(
//                        image,
//                        forKey: self.absoluteString as AnyObject,
//                        cost: data.count)
//                    DispatchQueue.main.async {
//                        completion(image)
//                    }
//                }
//            }
//        }
//        task.resume()
//    }
//}
extension FTChatMessageUserModel {
    static func getCurrentUserModel() -> FTChatMessageUserModel? {
        if let appUser = FIRAuth.auth()?.currentUser {
            let userID = appUser.uid
            let userName = appUser.displayName ?? appUser.email
            let userIconURL = appUser.photoURL?.absoluteString
            let senderModel = FTChatMessageUserModel(id: userID, name: userName, icon_url: userIconURL, extra_data: nil, isSelf: (AppState.sharedInstance.displayName == userName))
            return senderModel
        }
        return nil
    }
}
extension Date {
    static func getCurrentDateInString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let currentTime = Date()
        let dateFormatter  = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        let currentTimeInString = dateFormatter.string(from: currentTime as Date)
        return currentTimeInString
    }
}
extension FTChatMessageType {
    static func getMessageTypeFromString(messageType: String?) -> FTChatMessageType {
        guard let msgType = messageType else {
            return .text
        }
        switch msgType {
        case "text":
            return .text
        case "image":
            return .image
        case "audio":
            return .audio
        case "video":
            return .video
        case "location":
            return .location
        default:
            return .text
        }
    }
    static func getMessageStringFromType(messageType: FTChatMessageType) -> String {
        switch messageType {
        case .text:
            return "text"
        case .image:
            return "image"
        case .audio:
            return "audio"
        case .video:
            return "video"
        case .location:
            return "location"
        }
    }
}
extension UIButton {
    @IBInspectable var cornerRadius: CGFloat? {
        get {
            return self.cornerRadius
        }
        set {
            layer.cornerRadius = newValue ?? 0.0
            layer.masksToBounds = true
        }
    }
}
extension UITextField {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : "", attributes:[NSForegroundColorAttributeName: newValue!])
        }
    }
}
