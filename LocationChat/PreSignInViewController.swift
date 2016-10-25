//
//  PostSignedInViewController.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 19/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class PostSignedInViewController: UIViewController {

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
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customiseUI()
        if let user = FIRAuth.auth()?.currentUser {
            navigationItem.rightBarButtonItem?.isEnabled = true
            title = "Login as \(user.displayName!)"
            differentUserSignInButton.setTitle("Not \(user.displayName!) !!\n Sign in with different account ?", for: .normal)
            if user.photoURL != nil {
                ImageDownloader.default.downloadImage(with: user.photoURL!, options: [], progressBlock: nil) { [weak self] (image, error, url, data)  -> Void in
                    guard let strongSelf = self else { return }
                    if image != nil {
                        strongSelf.userImageView.image = image
                    }
                }
            }
        }
    }
    func customiseUI() {
        navigationItem.rightBarButtonItem = signInBarButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = false
        userImageView.layer.cornerRadius = userImageView.frame.size.width/2
        userImageView.layer.borderColor = UIColor.orange.cgColor
        userImageView.layer.borderWidth = 2.0
        userImageView.clipsToBounds = true
        userImageView.layer.masksToBounds = true
        userImageView.image = UIImage(named: "User")
        
        differentUserSignInButton.titleLabel?.textAlignment = .center
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Action
    func onTapSignIn() {
        SignInViewController.signedIn(FIRAuth.auth()?.currentUser, self, Constants.Segues.postSignedInToMap)
    }
    @IBAction func goToSignInVC(sender: UIButton) {
        UIApplication.shared.startNetworkActivity()
        SignInViewController.signOut { (didSignedOut, errorDesc) in
            if errorDesc != nil && !didSignedOut {
                let action = UIAlertAction(title: "Try Again", style: .default, handler: nil)
                self.showAlert(title: "Unable to Sign Out", contentText: errorDesc!, actions: [action])
            }
            else {
                self.performSegue(withIdentifier: Constants.Segues.postSignedInToSignInSegue, sender: self)
            }
            UIApplication.shared.stopNetworkActivity()
        }
    }
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
