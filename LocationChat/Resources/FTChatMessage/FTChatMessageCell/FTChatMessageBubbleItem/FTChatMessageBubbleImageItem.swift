//
//  FTChatMessageBubbleImageItem.swift
//  ChatMessageDemoProject
//
//  Created by liufengting on 16/5/7.
//  Copyright © 2016年 liufengting ( https://github.com/liufengting ). All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseStorage

class FTChatMessageBubbleImageItem: FTChatMessageBubbleItem {
    
    convenience init(frame: CGRect, aMessage : FTChatMessageModel, for indexPath: IndexPath) {
        self.init(frame:frame)
        self.backgroundColor = UIColor.clear
        message = aMessage
        
        let messageBubblePath = self.getBubbleShapePathWithSize(frame.size, isUserSelf: aMessage.isUserSelf, for: indexPath)

        let maskLayer = CAShapeLayer()
        maskLayer.path = messageBubblePath.cgPath
        maskLayer.frame = self.bounds
        
        let layer = CALayer()
        layer.mask = maskLayer
        layer.frame = self.bounds
        layer.contentsScale = UIScreen.main.scale
        layer.contentsGravity = kCAGravityResizeAspectFill
        layer.backgroundColor = aMessage.messageSender.isUserSelf ? FTDefaultOutgoingColor.cgColor : FTDefaultIncomingColor.cgColor
        self.layer.addSublayer(layer)
        
        if aMessage.isKind(of: FTChatMessageImageModel.classForCoder()) {
            if let image : UIImage = (aMessage as! FTChatMessageImageModel).image {
                layer.contents = image.withRenderingMode(.alwaysOriginal).cgImage
            }else  if let imageURL : String = (aMessage as! FTChatMessageImageModel).imageUrl {
                if imageURL.hasPrefix("gs://") {
                    FIRStorage.storage().reference(forURL: imageURL).data(withMaxSize: INT64_MAX){ (data, error) in
                        if let error = error {
                            print("Error downloading: \(error)")
                            return
                        }
                        if let image: UIImage = UIImage(data: data!) {
                            layer.contents = image.cgImage
                        }
                    }
                } else if let URL = URL(string: imageURL), let data = try? Data(contentsOf: URL), let image = UIImage(data: data) {
                    layer.contents = image.cgImage
                }
//                ImageDownloader.default.downloadImage(with: URL(string: imageURL)!, options: [], progressBlock: nil) {
//                    (image, error, url, data) in
//                    if image != nil {
//                        layer.contents = image?.cgImage
//                    }
//                }
            }
        }else{
            if let image = UIImage(named : "dog.jpg") {
                layer.contents = image.cgImage
            }
        }
    }
}
