//
//  FTChatMessageTableViewController.swift
//  ChatMessageDemoProject
//
//  Created by liufengting on 16/2/28.
//  Copyright © 2016年 liufengting ( https://github.com/liufengting ). All rights reserved.
//

import UIKit

class FTChatMessageTableViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, FTChatMessageInputViewDelegate, FTChatMessageHeaderDelegate {
    
    var chatMessageDataArray : [FTChatMessageModel] = [] {
        didSet {
            self.origanizeAndReload()
        }
    }
    open var messageArray : [[FTChatMessageModel]] = []
    var delegete : FTChatMessageDelegate?
    var dataSource : FTChatMessageDataSource?
    var messageInputMode : FTChatMessageInputMode = FTChatMessageInputMode.none
    
    lazy var messageTableView : UITableView! = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: FTScreenWidth, height: FTScreenHeight), style: .plain)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, FTDefaultInputViewHeight, 0)
        tableView.delegate = self
        tableView.dataSource = self
        
        let header = UIView(frame: CGRect( x: 0, y: 0, width: FTScreenWidth, height: FTDefaultMargin*2))
        tableView.tableHeaderView = header
        
        let footer = UIView(frame: CGRect( x: 0, y: 0, width: FTScreenWidth, height: FTDefaultInputViewHeight))
        tableView.tableFooterView = footer
        
        return tableView
    }()
    
    lazy var messageInputView : FTChatMessageInputView! = {
        let inputView : FTChatMessageInputView! = Bundle.main.loadNibNamed("FTChatMessageInputView", owner: nil, options: nil)?[0] as! FTChatMessageInputView
        inputView.frame = CGRect(x: 0, y: FTScreenHeight-FTDefaultInputViewHeight, width: FTScreenWidth, height: FTDefaultInputViewHeight)
        inputView.inputDelegate = self
        return inputView
    }()
    
    lazy var messageRecordView : FTChatMessageRecorderView! = {
        let recordView : FTChatMessageRecorderView! = Bundle.main.loadNibNamed("FTChatMessageRecorderView", owner: nil, options: nil)?[0] as! FTChatMessageRecorderView
        recordView.frame = CGRect(x: 0, y: FTScreenHeight, width: FTScreenWidth, height: FTDefaultAccessoryViewHeight)
        return recordView
    }()
    
    lazy var messageAccessoryView : FTChatMessageAccessoryView! = {
        let accessoryView = Bundle.main.loadNibNamed("FTChatMessageAccessoryView", owner: nil, options: nil)?[0] as! FTChatMessageAccessoryView
        accessoryView.frame = CGRect(x: 0, y: FTScreenHeight, width: FTScreenWidth, height: FTDefaultAccessoryViewHeight)
        return accessoryView
    }()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(messageTableView)
        
        self.view.addSubview(messageInputView)
        
        self.view.addSubview(messageRecordView)
        
        self.view.addSubview(messageAccessoryView)
        
        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.scrollToBottom(false)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageAccessoryView.setupAccessoryView()
    }
    
    internal func addNewMessage(_ message : FTChatMessageModel) {
        var messageDict: [String: String] = [:]
        messageDict[Constants.MessageFields.text] = message.messageText
        messageDict[Constants.MessageFields.name] = message.messageSender.senderName
        messageDict[Constants.MessageFields.userID] = message.messageSender.senderId
        messageDict[Constants.MessageFields.messageTime] = message.messageTimeStamp
        messageDict[Constants.MessageFields.messageType] = FTChatMessageType.getMessageStringFromType(messageType: message.messageType)
        messageDict[Constants.MessageFields.photoURL] = message.messageSender.senderIconUrl

        // Push data to Firebase Database
        AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).childByAutoId().setValue(messageDict)

        
        //chatMessageDataArray.append(message);
        //self.origanizeAndReload()
        //self.scrollToBottom(true)
    }
    internal func addNewImageMessage(_ message : FTChatMessageImageModel) {
        var messageDict: [String: String] = [:]
        messageDict[Constants.MessageFields.text] = message.messageText
        messageDict[Constants.MessageFields.name] = message.messageSender.senderName
        messageDict[Constants.MessageFields.userID] = message.messageSender.senderId
        messageDict[Constants.MessageFields.messageTime] = message.messageTimeStamp
        messageDict[Constants.MessageFields.messageType] = FTChatMessageType.getMessageStringFromType(messageType: message.messageType)
        messageDict[Constants.MessageFields.photoURL] = message.messageSender.senderIconUrl
        messageDict[Constants.MessageFields.imageURL] = message.imageUrl

        // Push data to Firebase Database
        AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).childByAutoId().setValue(messageDict)
        
        
        //chatMessageDataArray.append(message);
        //self.origanizeAndReload()
        //self.scrollToBottom(true)
    }
    
    func origanizeAndReload() {
        var nastyArray : [[FTChatMessageModel]] = []
        var tempArray : [FTChatMessageModel] = []
        var tempId = ""
        for i in 0...chatMessageDataArray.count-1 {
            let message = chatMessageDataArray[i]
            if message.messageSender.senderId == tempId {
                tempArray.append(message)
            }else{
                tempId = message.messageSender.senderId;
                if tempArray.count > 0 {
                    nastyArray.append(tempArray)
                }
                tempArray.removeAll()
                tempArray.append(message)
            }
            if i == chatMessageDataArray.count - 1 {
                if tempArray.count > 0 {
                    nastyArray.append(tempArray)
                }
            }
        }
        
        self.messageArray = nastyArray
        self.messageTableView.reloadData()
    }
}
