//
//  SignInViewController.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 15/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseStorage
import QuartzCore
import MobileCoreServices

class SignInViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: IBOutlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var btnUserProfile: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    // MARK: Variables
    var didImageChange = false
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        customiseUI()

//        do {
//            try FIRAuth.auth()?.signOut()
//            AppState.sharedInstance.signedIn = false
//
//        } catch let signOutError as NSError {
//            print ("Error signing out: \(signOutError.localizedDescription)")
//        }

        //        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
        //            if let user = user {
        //
        //            } else {
        //            }
        //        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    // MARK: UI
    func customiseUI() {
        btnUserProfile.layer.cornerRadius = btnUserProfile.frame.size.width / 2.0
        btnUserProfile.layer.borderColor = UIColor.orange.cgColor
        btnUserProfile.layer.borderWidth = 2.0
        btnUserProfile.layer.masksToBounds = true
        btnUserProfile.clipsToBounds = true
        
        print("Screen height: \(UIScreen.main.bounds.height)")
        if UIScreen.main.bounds.height <= 568.0 {
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidShow, object: nil, queue: OperationQueue.main) { (notification) in
                
                if self.topConstraint.constant == 0.0 {
                    self.view.layoutIfNeeded()
                    UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10.0, options: UIViewAnimationOptions(), animations: ({
                        // do stuff
                        self.topConstraint.constant -= (self.navigationController!.navigationBar.frame.size.height + self.navigationController!.navigationBar.frame.origin.y + UIApplication.shared.statusBarFrame.size.height + UIApplication.shared.statusBarFrame.origin.y + 44.0)
                        self.view.layoutIfNeeded()
                        
                    }), completion: { (value: Bool) in
                    })
                }
            }
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidHide, object: nil, queue: OperationQueue.main) { (notification) in
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10.0, options: UIViewAnimationOptions(), animations: ({
                    // do stuff
                    self.topConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }), completion: { (value: Bool) in
                })
            }
        }
        
    }
    
    // MARK: Actions
    @IBAction func didTapSignIn(_ sender: AnyObject) {
        // Sign In with credentials.
        UIApplication.shared.startNetworkActivity()
        
        if !self.checkMandatoryFields(isForSignUp: false) {
            UIApplication.shared.stopNetworkActivity()
            return
        }
        FIRAuth.auth()?.signIn(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                UIApplication.shared.stopNetworkActivity()
                let alertAction = UIAlertAction(title: "Try again", style: .default, handler: nil)
                self.showAlert(title: "Unable to sign you in", contentText: error.localizedDescription, actions: [alertAction])
            }
            else {
                UIApplication.shared.stopNetworkActivity()
                if self.didImageChange {
                    // Set profile picture
                    self.changeProfilePicture(user: user!, completion: { (succeded, errorDesc, downloadURL) in
                        if errorDesc != nil && !succeded {
                            self.showAlert(title: "Unable to sign you up!", contentText: error!.localizedDescription, actions: [UIAlertAction.init(title: "try Again", style: .default, handler: nil)])
                        }
                        else {
                            self.setParameterChangeRequest(user!, iconUrl: downloadURL, isForSignUp: false)
                        }
                    })
                }
                SignInViewController.signedIn(user!, self, Constants.Segues.signInToMap)
            }
        }
    }
    @IBAction func didTapSignUp(_ sender: AnyObject) {
        UIApplication.shared.startNetworkActivity()
        
        if !self.checkMandatoryFields(isForSignUp: true) {
            UIApplication.shared.stopNetworkActivity()
            return
        }
        
        
        FIRAuth.auth()?.createUser(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                self.showAlert(title: "Unable to create your Account!", contentText: error.localizedDescription, actions: [alertAction])
                UIApplication.shared.stopNetworkActivity()
                return
            }
            // Set profile picture
            self.changeProfilePicture(user: user!, completion: { (succeded, errorDesc, downloadURL) in
                if errorDesc != nil && !succeded {
                    self.showAlert(title: "Unable to sign you up!", contentText: error!.localizedDescription, actions: [UIAlertAction.init(title: "try Again", style: .default, handler: nil)])
                }
                else {
                    self.setParameterChangeRequest(user!, iconUrl: downloadURL, isForSignUp: true)
                }
            })
        }
    }
    @IBAction func didRequestPasswordReset(_ sender: AnyObject) {
        let prompt = UIAlertController.init(title: nil, message: "Email:", preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default) { (action) in
            let userInput = prompt.textFields![0].text
            if (userInput!.isEmpty) {
                return
            }
            FIRAuth.auth()?.sendPasswordReset(withEmail: userInput!) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
            }
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil);
    }
    @IBAction func onChangeProfileImage(sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    func setParameterChangeRequest(_ user: FIRUser, iconUrl: URL?, isForSignUp: Bool) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = isForSignUp ? displayNameField.text ?? "" : user.displayName ?? ""
        if iconUrl != nil {
            changeRequest.photoURL = iconUrl!
        }
        changeRequest.commitChanges(){ (error) in
            UIApplication.shared.stopNetworkActivity()
            if let error = error {
                print(error.localizedDescription)
                return
            }
            // Signing in..
            if self.didImageChange {
                self.didImageChange = false
            }
            SignInViewController.signedIn(FIRAuth.auth()?.currentUser, self, Constants.Segues.signInToMap)
        }
    }
    func changeProfilePicture(user: FIRUser, completion: @escaping (_ success: Bool, _ errorDesc: String?, _ _downloadURL: URL?) -> Void) {
        let data = UIImagePNGRepresentation(self.btnUserProfile.imageView!.image!)
        let filePath = "\(user.uid)/\("userPhoto")"
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/png"
        AppState.sharedInstance.storageRef.child(filePath).put(data!, metadata: metaData, completion: { (metaData, error) in
            var downloadURL: URL? = nil
            if let error = error {
                print(error.localizedDescription)
                completion(false, error.localizedDescription, nil)
            }else{
                //store downloadURL
                downloadURL = metaData!.downloadURL()!
                //store downloadURL at database
                AppState.sharedInstance.firebaseRef.child(Constants.UserFields.users).child(FIRAuth.auth()!.currentUser!.uid).updateChildValues([Constants.UserFields.userPhoto: downloadURL!.absoluteString])
                completion(true, nil, downloadURL)
            }
        })
    }
    // MARK: Validation
    func checkMandatoryFields(isForSignUp: Bool) -> Bool {
        guard let email = emailField.text, !email.isEmpty else {
            emailField.shake()
            emailField.becomeFirstResponder()
            return false
        }
        if !isValidEmail(emailID: emailField.text!) {
            emailField.shake()
            emailField.becomeFirstResponder()
            return false
        }
        if isForSignUp { // Display name is mandatory only for Sign Up
            guard let displayName = displayNameField.text, !displayName.isEmpty else {
                displayNameField.shake()
                displayNameField.becomeFirstResponder()
                return false
            }
        }
        guard let password = passwordField.text, !password.isEmpty else {
            emailField.shake()
            emailField.becomeFirstResponder()
            return false
        }
        return true
    }
    func isValidEmail(emailID:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailID)
    }
    
    // MARK: - Navigation
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
}
extension SignInViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            btnUserProfile.contentMode = .scaleAspectFill
            btnUserProfile.setImage(pickedImage, for: .normal)
            didImageChange = true
        }
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    class func signOut(completion: @escaping (_ success: Bool, _ errorDesc: String?) -> Void) {
        if let firebaseAuth = FIRAuth.auth() { //, let userID = firebaseAuth.currentUser?.uid {
            do {
                try firebaseAuth.signOut()
                completion(true, nil)

            } catch let signOutError as NSError {
                print ("Error signing out: \(signOutError.localizedDescription)")
                completion(false, signOutError.localizedDescription)
            }

//            AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).child(userID).removeValue(completionBlock: { (error, databaseRef) in
//                if error == nil {
//                    print("Deleted data: \(databaseRef.description())")
//                    do {
//                        try firebaseAuth.signOut()
//                        completion(true, nil)
//                        
//                    } catch let signOutError as NSError {
//                        print ("Error signing out: \(signOutError.localizedDescription)")
//                        completion(false, signOutError.localizedDescription)
//                    }
//                }
//                else {
//                    print("Error signing out: \(error!.localizedDescription)")
//                    completion(false, error!.localizedDescription)
//                }
//            })
        }
        else {
            completion(false, "There's some unknown error occured, please try again after some time.")
        }
    }
    class func signedIn(_ user: FIRUser?, _ vc: UIViewController, _ segueID: String) {
        MeasurementHelper.sendLoginEvent()
        print(user?.description)
        print(user?.displayName)
        print(user?.email)
        print(user?.photoURL)
        
        
        AppState.sharedInstance.displayName = user?.displayName ?? user?.email
        AppState.sharedInstance.photoURL = user?.photoURL
        ChatLocation.sharedInstance.initialiseCoreLocation()
        vc.performSegue(withIdentifier: segueID, sender: vc)
    }
}
