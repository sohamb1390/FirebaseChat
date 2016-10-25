//
//  ViewController.swift
//  LocationChat
//
//  Created by Soham Bhattacharjee on 14/10/16.
//  Copyright © 2016 Soham Bhattacharjee. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CoreLocation

let SEARCH_RADIUS = 200.0
let VIEW_SIZE = 1500
let SPAN = 0.005


class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var selectedAnnotation: MKAnnotation?
    var oldLocation: CLLocation?
    fileprivate var _refHandleForAddedLocation: FIRDatabaseHandle!
    fileprivate var _refHandleForUpdatedLocation: FIRDatabaseHandle!
    fileprivate var _refHandleForDeletedLocation: FIRDatabaseHandle!
    
    fileprivate var arrLocations: [FIRDataSnapshot] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.hidesBackButton = true
        title = "My Network"
        initialiseMap()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).removeObserver(withHandle: _refHandleForAddedLocation)
        AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).removeObserver(withHandle: _refHandleForUpdatedLocation)
        AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).removeObserver(withHandle: _refHandleForDeletedLocation)
        
        arrLocations.removeAll()
        
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
// MARK: - Map helpers
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        let identifier = "pin"
        var view : MKPinAnnotationView
        if let dequeueView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView{
            dequeueView.annotation = annotation
            view = dequeueView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            //view.calloutOffset = CGPoint(x: -5, y: 5)
            //view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        let colorPointAnnotation = annotation as! ColorPointAnnotation
        view.pinTintColor = colorPointAnnotation.pinColor
        return view
    }
    func updateCirclePosition(location: CLLocation) {
        self.mapView.removeOverlays(self.mapView.overlays)
        let circle = MKCircle(center: location.coordinate, radius: SEARCH_RADIUS as CLLocationDistance)
        self.mapView.add(circle)
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleView = MKCircleRenderer(overlay: overlay)
        circleView.strokeColor = UIColor.red
        circleView.fillColor = UIColor.red.withAlphaComponent(0.2)
        circleView.lineWidth = 0.5
        return circleView;
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    }
    
    func reverseGeoLocation(annotation: ColorPointAnnotation) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)) { placemarks, error in
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
            }
            else {
                if let placemark = placemarks?.first, let placeName = placemark.name, let locality = placemark.locality {
                    annotation.subtitle = "\(placeName)\n\(locality)"
                }
                else {
                    annotation.subtitle = "Unknown Place"
                }
            }
        }
    }
    
    // MARK: Navigation
    @IBAction func goToChatRoom(sender: AnyObject) {
        performSegue(withIdentifier: Constants.Segues.mapToChat, sender: self)
    }
}
// MARK: - CLLocation Helpers
extension ViewController: CLLocationManagerDelegate {
    func initialiseMap() {
        self.mapView.showsUserLocation = false
        self.mapView.delegate = self
        self.mapView.isZoomEnabled = true
        self.mapView.isScrollEnabled = true
        arrLocations.removeAll()
        
        _refHandleForAddedLocation = AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).observe(.childAdded, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else {
                return
            }
            if let _ = snapshot.value as? [String : AnyObject] {
                strongSelf.arrLocations.append(snapshot)
                strongSelf.updateMapViewOnLocationUpdates(arrSnapshots: strongSelf.arrLocations)
                print("Location Array Details: \(strongSelf.arrLocations)")
            }
            })
        _refHandleForUpdatedLocation = AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).observe(.childChanged, with: {  [weak self] (snapshot) -> Void in
            guard let strongSelf = self else {
                return
            }
            if let _ = snapshot.value as? [String : AnyObject] {
                if let index = strongSelf.arrLocations.index(of: snapshot) {
                    strongSelf.arrLocations[index] = snapshot
                    strongSelf.updateMapViewOnLocationUpdates(arrSnapshots: strongSelf.arrLocations)
                    print("Location Array Details: \(strongSelf.arrLocations)")
                }
            }
            }, withCancel: { (error) in
                
        })
        _refHandleForDeletedLocation = AppState.sharedInstance.firebaseRef.child(Constants.LocationFields.userLocation).observe(.childRemoved, with: {  [weak self] (snapshot) -> Void in
            guard let strongSelf = self else {
                return
            }
            if let index = strongSelf.arrLocations.index(of: snapshot) {
                strongSelf.arrLocations.remove(at: index)
                print("Location Array Details: \(strongSelf.arrLocations)")
                strongSelf.updateMapViewOnLocationUpdates(arrSnapshots: strongSelf.arrLocations)
            }
            
            }, withCancel: { (error) in
                
        })
    }
    func updateMapViewOnLocationUpdates(arrSnapshots: [FIRDataSnapshot]) {
        
        // Reset
        self.mapView.removeAnnotations(self.mapView.annotations)
        if self.selectedAnnotation != nil {
            self.mapView.deselectAnnotation(self.selectedAnnotation, animated: true)
            self.selectedAnnotation = nil
        }
        var arrAnnotations: [ColorPointAnnotation] = []
        
        for snapshot in arrSnapshots {
            autoreleasepool(invoking: { () in
                if let dict: [String: AnyObject] = snapshot.value as? [String: AnyObject],
                    let lat = dict[Constants.LocationFields.userLatitude] as? String,
                    let long = dict[Constants.LocationFields.userLongitude] as? String,
                    let userName = dict[Constants.LocationFields.userName] as? String {
                    
                    let annotation = ColorPointAnnotation(pinColor: UIColor.blue)
                    annotation.coordinate = CLLocationCoordinate2D(latitude: Double(lat)!, longitude: Double(long)!)
                    annotation.title = userName
                    arrAnnotations.append(annotation)
                    self.reverseGeoLocation(annotation: annotation)
                    
                    // Draw circle
                    if let currentUser = FIRAuth.auth()?.currentUser {
                        let displayName: String = currentUser.displayName!
                        if displayName == userName {
                            annotation.title = "\(displayName) (You)"
                            annotation.pinColor = UIColor.green
                            let newRegion = MKCoordinateRegion(center:annotation.coordinate , span: MKCoordinateSpanMake(SPAN, SPAN))
                            self.mapView.setRegion(newRegion, animated: true)
                            self.updateCirclePosition(location: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))
                        }
                    }
                }
            })
        }
        // add new annotations
        self.mapView.addAnnotations(arrAnnotations)
    }
}
// MARK: - Extensions
extension UIView {
    class func loadFromNibNamed(nibNamed: String, bundle : Bundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiate(withOwner: nil, options: nil)[0] as? UIView
    }
}
extension Int {
    func format(f: String) -> String {
        return String(format: "%\(f)d", self)
    }
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
