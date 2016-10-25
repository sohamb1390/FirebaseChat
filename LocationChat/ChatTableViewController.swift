//
//  ChatTableViewController.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 18/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import FTIndicator
import Firebase
import FirebaseStorage
import FirebaseRemoteConfig
import FirebaseCrash
import Photos

class ChatTableViewController: FTChatMessageTableViewController,FTChatMessageAccessoryViewDelegate,FTChatMessageAccessoryViewDataSource,FTChatMessageRecorderViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    // MARK: Variables
    fileprivate var messages: [FIRDataSnapshot]! = []
    var _refHandleForAddedMessages: FIRDatabaseHandle!
    var _refHandleForRemovedMessages: FIRDatabaseHandle!
    var _refHandleForChangedMessages: FIRDatabaseHandle!
    fileprivate var remoteConfig: FIRRemoteConfig!
    
    // Bar buttons
    lazy var refreshBarButtonItem: UIBarButtonItem = { [unowned self] in
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(fetchConfig))
        return barButtonItem
        }()
    lazy var signOutBarButtonItem: UIBarButtonItem = { [unowned self] in
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "logout"), style: .done, target: self, action: #selector(onTapSignOut))
        barButtonItem.tintColor = UIColor.white
        return barButtonItem
        }()
    lazy var backBarButtonItem: UIBarButtonItem = { [unowned self] in
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "location"), style: .done, target: self, action: #selector(back))
        barButtonItem.tintColor = UIColor.white
        return barButtonItem
        }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        messageRecordView.recorderDelegate = self
        messageAccessoryView.setupWithDataSource(self , accessoryViewDelegate : self)
        
        // customise UI
        customiseUI()
        
        // Setup Firebase
        configureDatabase()
        configureRemoteConfig()
        fetchConfig()
        logViewLoaded()
    }
    override func viewWillDisappear(_ animated: Bool) {
        AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).removeObserver(withHandle: _refHandleForAddedMessages)
        AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).removeObserver(withHandle: _refHandleForRemovedMessages)
        AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).removeObserver(withHandle: _refHandleForChangedMessages)
        
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI
    func customiseUI() {
        title = "My Chat Room"
        navigationItem.rightBarButtonItems = [signOutBarButtonItem, refreshBarButtonItem]
        navigationItem.leftBarButtonItem = backBarButtonItem
    }
    
    // MARK: Incoming Message Helpers
    func getAccessoryItemTitleArray() -> [String] {
        //return ["Alarm","Camera","Contacts","Mail","Messages","Music","Phone","Photos","Settings","VideoChat","Videos","Weather"]
        return ["Photos", "Camera"]
    }
}

// MARK: - Firebase DB handlers
extension ChatTableViewController {
    
    fileprivate func getMessageModel(messageSnapshot: FIRDataSnapshot) -> FTChatMessageModel? {
        let messageDict = messageSnapshot.value as! Dictionary<String, String>
        
        guard let userName = messageDict[Constants.MessageFields.name] as String!,
            let userID = messageDict[Constants.MessageFields.userID] as String!,
            let text = messageDict[Constants.MessageFields.text] as String! else {
                return nil
        }
        let messageTime = messageDict[Constants.MessageFields.messageTime] as String!
        let messageType = FTChatMessageType.getMessageTypeFromString(messageType: messageDict[Constants.MessageFields.messageType] as String!)
        let userIconURL = messageDict[Constants.MessageFields.photoURL] as String!
        let imageURL = messageDict[Constants.MessageFields.imageURL] as String!
        let senderModel = FTChatMessageUserModel(id: userID, name: userName, icon_url: userIconURL, extra_data: nil, isSelf: (AppState.sharedInstance.displayName == userName))
        if messageType == .image {
            let imageChatModel = FTChatMessageImageModel(data: text, time: messageTime, extraDic: nil, from: senderModel, type: messageType)
            imageChatModel.imageUrl = imageURL
            return imageChatModel
        }
        return FTChatMessageModel(data: text, time: messageTime, extraDic: nil, from: senderModel, type: messageType)
    }
    func configureDatabase() {
        // Listen for new messages in the Firebase database
        _refHandleForAddedMessages = AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).observe(.childAdded, with: { [weak self] (messageSnapshot) -> Void in
            guard let strongSelf = self else { return }
            if let messageModel = strongSelf.getMessageModel(messageSnapshot: messageSnapshot) {
                strongSelf.chatMessageDataArray.append(messageModel)
                strongSelf.origanizeAndReload()
                strongSelf.scrollToBottom(true)
            }
            })
        // Listen for deleted comments in the Firebase database
        _refHandleForRemovedMessages = AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).observe(.childRemoved, with: { [weak self] (messageSnapshot) -> Void in
            guard let strongSelf = self else { return }
            if let messageModel = strongSelf.getMessageModel(messageSnapshot: messageSnapshot) {
                if let index = strongSelf.chatMessageDataArray.index(of: messageModel) {
                    strongSelf.chatMessageDataArray.remove(at: index)
                    strongSelf.origanizeAndReload()
                }
            }
            })
        // Listen for changed comments in the Firebase database
        _refHandleForChangedMessages = AppState.sharedInstance.firebaseRef.child(Constants.MessageFields.messages).observe(.childChanged, with: { [weak self] (messageSnapshot) -> Void in
            guard let strongSelf = self else { return }
            if let messageModel = strongSelf.getMessageModel(messageSnapshot: messageSnapshot) {
                if let index = strongSelf.chatMessageDataArray.index(of: messageModel) {
                    strongSelf.chatMessageDataArray[index] = messageModel
                    strongSelf.origanizeAndReload()
                }
            }
            })
    }
    
    func configureRemoteConfig() {
        remoteConfig = FIRRemoteConfig.remoteConfig()
        // Create Remote Config Setting to enable developer mode.
        // Fetching configs from the server is normally limited to 5 requests per hour.
        // Enabling developer mode allows many more requests to be made per hour, so developers
        // can test different config values during development.
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
    }
    
    func fetchConfig() {
        var expirationDuration: Double = 3600
        // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
        // the server.
        if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
            expirationDuration = 0
        }
        
        // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
        // fetched and cached config would be considered expired because it would have been fetched
        // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
        // throttling is in progress. The default expiration duration is 43200 (12 hours).
        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
            if (status == .success) {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error)")
            }
        }
    }
    func logViewLoaded() {
        FIRCrashMessage("View loaded")
    }
    func onTapSignOut() {
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (action) -> Void in
            UIApplication.shared.startNetworkActivity(info: nil)
            SignUpViewController.signOut(completion: { (didSignOut, errorDesc) in
                UIApplication.shared.startNetworkActivity(info: nil)
                if errorDesc != nil && !didSignOut {
                    let action = UIAlertAction(title: "Try Again", style: .default, handler: nil)
                    self.showAlert(title: "Unable to Sign Out", contentText: errorDesc!, actions: [action])
                }
                else {
                    self.performSegue(withIdentifier: Constants.Segues.unwindToSignUp, sender: self)
                }
            })
        }
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        showAlert(title: "Do you really want to sign out?", contentText: "We will keep your data alive while you are signed off but your location will be removed", actions: [yesAction, noAction])
    }
    
    // MARK: - Navigation
    func back() {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - FTChatMessageAccessory Helpers
extension ChatTableViewController {
    
    func ftChatMessageAccessoryViewModelArray() -> [FTChatMessageAccessoryViewModel] {
        var array : [FTChatMessageAccessoryViewModel] = []
        let titleArray = self.getAccessoryItemTitleArray()
        for i in 0...titleArray.count - 1 {
            let string = titleArray[i]
            array.append(FTChatMessageAccessoryViewModel.init(title: string, iconImage: UIImage(named: string)!))
        }
        return array
    }
    func ftChatMessageAccessoryViewDidTappedOnItemAtIndex(_ index: NSInteger) {
        // Here I have only implemented photos & camera
        let imagePicker: UIImagePickerController = UIImagePickerController()
        imagePicker.delegate = self
        switch index {
        case 0:
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
            break
        case 1:
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
            break
        default:
            print("I just tapped at accessory view at index : \(index)")
        }
        //        if index == 0 {
        ////            let imagePicker : UIImagePickerController = UIImagePickerController()
        ////            imagePicker.sourceType = .photoLibrary
        ////            imagePicker.delegate = self
        ////            self.present(imagePicker, animated: true, completion: {
        ////            })
        //        } else {
        ////            let string = "I just tapped at accessory view at index : \(index)"
        ////            print(string)
        ////
        ////            //        FTIndicator.showInfo(withMessage: string)
        ////
        ////            let message2 = FTChatMessageModel(data: string, time: "4.12 21:09:51", from: sender2, type: .text)
        ////            self.addNewMessage(message2)
        //        }
    }
    
    // MARK: FTChatMessageRecorderViewDelegate
    func ft_chatMessageRecordViewDidStartRecording(){
        print("Start recording...")
        FTIndicator.showProgressWithmessage("Recording...")
    }
    func ft_chatMessageRecordViewDidCancelRecording(){
        print("Recording canceled.")
        FTIndicator.dismissProgress()
    }
    func ft_chatMessageRecordViewDidStopRecording(_ duriation: TimeInterval, file: Data?){
        print("Recording ended!")
        //        FTIndicator.showSuccess(withMessage: "Record done.")
        //
        //        let message2 = FTChatMessageModel(data: "", time: "4.12 21:09:51", from: sender2, type: .audio)
        //        self.addNewMessage(message2)
    }
    func saveImageToDisk(image: UIImage) -> String {
        return ""
    }
}
// MARK: - UIImagePickerController helpers
extension ChatTableViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true) {
            guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
            
            // if it's a photo from the library, not an image from the camera
            if #available(iOS 8.0, *), let referenceURL = info[UIImagePickerControllerReferenceURL] {
                let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL as! URL], options: nil)
                let asset = assets.firstObject
                UIApplication.shared.startNetworkActivity(info: nil)
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFile = contentEditingInput?.fullSizeImageURL
                    // Adding file path name
                    // You can choose whatever name you want
                    let filePath = "\(uid)/\(Date.getCurrentDateInString(dateStyle: .long, timeStyle: .medium))/\((referenceURL as AnyObject).lastPathComponent!)"
                    AppState.sharedInstance.storageRef.child(filePath)
                        .putFile(imageFile!, metadata: nil) { (metadata, error) in
                            if let error = error {
                                self.showAlert(title: "Unable to send your chat", contentText: error.localizedDescription, actions: [UIAlertAction.init(title: "Try again", style: .default, handler: nil)])
                                UIApplication.shared.stopNetworkActivity()
                                return
                            }
                            guard let messageUserModel = FTChatMessageUserModel.getCurrentUserModel() else { return }
                            let message = FTChatMessageImageModel(data: "", time: Date.getCurrentDateInString(dateStyle: .long, timeStyle: .medium), extraDic: nil, from: messageUserModel, type: .image)
                            
                            let manager = PHImageManager.default()
                            let option = PHImageRequestOptions()
                            var thumbnail = UIImage()
                            option.isSynchronous = true
                            manager.requestImage(for: asset!, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
                                thumbnail = result!
                                message.image = thumbnail
                                message.imageUrl = AppState.sharedInstance.storageRef.child(metadata!.path!).description
                                self.addNewImageMessage(message)
                                UIApplication.shared.stopNetworkActivity()
                            })
                    }
                })
            } else {
                guard let image = info[UIImagePickerControllerOriginalImage] as! UIImage? else { return }
                let imageData = UIImageJPEGRepresentation(image, 0.8)
                // Adding file path name
                // You can choose whatever name you want
                let imagePath = "\(uid)/\(Date.getCurrentDateInString(dateStyle: .long, timeStyle: .medium)).jpg"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                AppState.sharedInstance.storageRef.child(imagePath)
                    .put(imageData!, metadata: metadata) { (metadata, error) in
                        if let error = error {
                            self.showAlert(title: "Unable to send your chat", contentText: error.localizedDescription, actions: [UIAlertAction.init(title: "Try again", style: .default, handler: nil)])
                            return
                        }
                        guard let messageUserModel = FTChatMessageUserModel.getCurrentUserModel() else { return }
                        let message = FTChatMessageImageModel(data: "", time: Date.getCurrentDateInString(dateStyle: .long, timeStyle: .medium), extraDic: nil, from: messageUserModel, type: .image)
                        message.image = image
                        message.imageUrl = AppState.sharedInstance.storageRef.child(metadata!.path!).description
                        self.addNewImageMessage(message)
                        
                        //self.sendMessage(withData: [Constants.MessageFields.imageURL: strongSelf.storageRef.child((metadata?.path)!).description])
                }
            }
        }
        //        picker.dismiss(animated: true) {
        //            let image : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        //            if let mesageModel = FTChatMessageUserModel.getCurrentUserModel() {
        //                let message = FTChatMessageImageModel(data: "", time: Date.getCurrentDateInString(dateStyle: .long), extraDic: nil, from: mesageModel, type: .image)
        //                message.image = image
        //                self.addNewMessage(message)
        //            }
        //            else {
        //                print("App User not found")
        //            }
        //        }
    }
}
