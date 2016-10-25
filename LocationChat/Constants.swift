//
//  Constants.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 15/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import CoreLocation
import Firebase
import MapKit

struct Constants {
    
    struct NotificationKeys {
        static let SignedIn = "onSignInCompleted"
    }
    
    struct Segues {
        static let signInToMap = "SignInToMapSegue"
        static let preSignInToMap = "PreSignInToMapSegue"
        static let preSignInToSignUpSegue = "PreSignInToSignUpSegue"

        static let mapToChat = "MapToChatSegue"
        static let newSignIn = "NewSignInVC"
        static let unwindToSignUp = "UnwindToSignUpSegue"
    }
    
    struct MessageFields {
        static let userID = "userID"
        static let name = "name"
        static let text = "text"
        static let messageTime = "messageTime"
        static let photoURL = "photoURL"
        static let imageURL = "imageURL"
        static let messages = "messages"
        static let messageType = "messageType"
    }
    
    struct UserFields {
        static let users = "users"
        static let userPhoto = "userPhoto"
    }
    
    struct LocationFields {
        static let userLocation = "Location"
        static let userLatitude = "Latitude"
        static let userLongitude = "Longitude"
        static let userName = "UserName"
    }
    
    struct AppConstants {
        static let storage_url = "gs://locationchat-3d569.appspot.com"
        static let chatCellID = "ChatCellID"
    }
}

class ChatLocation: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = ChatLocation()
    let locationManager = CLLocationManager()
    
    func initialiseCoreLocation() {
        // Ask for Authorisation from the User.
        locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.distanceFilter = 10.0
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startUpdatingLocation()
        }
    }
    func stopLocationUpdate() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.delegate = nil
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Unable to update your location :\(error.localizedDescription)")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationObj = locations.last {
            if let appUser = FIRAuth.auth()?.currentUser {
                let locationDict: [String: String] =
                    [Constants.LocationFields.userLatitude: String(locationObj.coordinate.latitude) as String,
                     Constants.LocationFields.userLongitude: String(locationObj.coordinate.longitude) as String,
                     Constants.LocationFields.userName: appUser.displayName! as String]
                
                AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).child(appUser.uid).setValue(locationDict)
            }
        }
    }
}
class ColorPointAnnotation: MKPointAnnotation {
    var pinColor: UIColor
    
    init(pinColor: UIColor) {
        self.pinColor = pinColor
        super.init()
    }
}
