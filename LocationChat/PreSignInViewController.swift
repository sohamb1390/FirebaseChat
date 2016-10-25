//
//  PreSignInViewController.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 19/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher
import PKHUD
class PreSignInViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var differentUserSignInButton: UIButton!
    
    // MARK: Variables
    lazy var signInBarButtonItem: UIBarButtonItem = { [unowned self] in
        let barButtonItem = UIBarButtonItem(title: "Sign In", style: .done, target: self, action: #selector(onTapSignIn))
        return barButtonItem
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.userImageView.contentMode = .scaleAspectFill

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customiseUI()
        checkUserSignInStatus()
    }
    func customiseUI() {
        userImageView.layer.cornerRadius = userImageView.frame.size.width/2
        userImageView.layer.borderColor = UIColor.orange.cgColor
        userImageView.layer.borderWidth = 2.0
        userImageView.clipsToBounds = true
        userImageView.layer.masksToBounds = true
        userImageView.image = UIImage(named: "User")
        differentUserSignInButton.titleLabel?.textAlignment = .center
        differentUserSignInButton.titleLabel?.text = "No User is signed In"
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.white]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict as? [String : Any]

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Action
    func onTapSignIn() {
        SignUpViewController.signedIn(FIRAuth.auth()?.currentUser, self, Constants.Segues.preSignInToMap)
    }
    @IBAction func goToSignInVC(sender: UIButton) {
        UIApplication.shared.startNetworkActivity(info: nil)
        SignUpViewController.signOut { (didSignedOut, errorDesc) in
            if errorDesc != nil && !didSignedOut {
                let action = UIAlertAction(title: "Try Again", style: .default, handler: nil)
                self.showAlert(title: "Unable to Sign Out", contentText: errorDesc!, actions: [action])
            }
            else {
                self.performSegue(withIdentifier: Constants.Segues.preSignInToSignUpSegue, sender: self)
            }
            UIApplication.shared.stopNetworkActivity()
        }
    }
    
    // MARK: User Status
    func checkUserSignInStatus() {
        if let user = FIRAuth.auth()?.currentUser {
            UIApplication.shared.startNetworkActivity(info: "Checking previous session")
            user.getTokenWithCompletion({ [weak self] (token, error) -> Void in
                guard let strongSelf = self else { return }
                if error != nil {
                    print("Token Expired: \(error)")
                    HUD.show(.labeledProgress(title: "Signing Out", subtitle: "No previous session found hence signing out.."))
                    SignUpViewController.signOut(completion: { (didSignOut, errorDesc) in
                        UIApplication.shared.stopNetworkActivity()
                        if errorDesc != nil && !didSignOut {
                            strongSelf.showAlert(title: "Unable to sign out", contentText: errorDesc!, actions: [UIAlertAction.init(title: "Try Again", style: .default, handler: { (action) in
                                strongSelf.checkUserSignInStatus()
                            })])
                        }
                        else {
                            strongSelf.performSegue(withIdentifier: Constants.Segues.preSignInToSignUpSegue, sender: self)
                        }
                    })
                }
                else {
                    strongSelf.navigationItem.rightBarButtonItem = strongSelf.signInBarButtonItem
                    strongSelf.title = "Login as \(user.displayName!)"
                    strongSelf.differentUserSignInButton.setTitle("Not \(user.displayName!) !!\n Sign in with different account ?", for: .normal)
                    HUD.show(.labeledProgress(title: "Just a moment", subtitle: "Downloading User Picture"))
                    strongSelf.downloadUserPicture(user: user)
                }
            })
        }
        else {
            // No user is signed in.
            self.performSegue(withIdentifier: Constants.Segues.preSignInToSignUpSegue, sender: self)
        }
    }
    func downloadUserPicture(user: FIRUser) {
        if user.photoURL != nil {
            ImageDownloader.default.downloadImage(with: user.photoURL!, options: [], progressBlock: nil) { [weak self] (image, error, url, data)  -> Void in
                guard let strongSelf = self else { return }
                UIApplication.shared.stopNetworkActivity()
                if image != nil {
                    strongSelf.userImageView.image = image
                }
                else {
                    strongSelf.showAlert(title: "Unable to download the picture", contentText: "Please check your newtwork connection", actions: [UIAlertAction.init(title: "Ok", style: .default, handler: nil)])
                }
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
