//
//  AppState.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 15/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import EasyTipView

class AppState: NSObject {
    
    static let sharedInstance = AppState()
    
    var displayName: String?
    var photoURL: URL?
    let firebaseRef = FIRDatabase.database().reference()
    let storageRef = FIRStorage.storage().reference(forURL: Constants.AppConstants.storage_url)
    
    func setToolTipPreferences() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont.systemFont(ofSize: 14.0)
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = UIColor.black
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.any
        
        /*
         * Optionally you can make these preferences global for all future EasyTipViews
         */
        EasyTipView.globalPreferences = preferences

    }

}
