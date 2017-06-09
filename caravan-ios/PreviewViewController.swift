//
//  PreviewViewController.swift
//  caravan-ios
//
//  Created by Renee Liu on 6/7/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import Foundation
import UIKit
import Mapbox
import MapboxDirections
import MapboxNavigation
import MapboxGeocoder
import FirebaseDatabase
import FirebaseAuth
import Firebase

class PreviewViewController: UIViewController {
    
    @IBOutlet weak var room: UILabel!
    @IBOutlet var preview: MGLMapView!
    
    var geocoder: Geocoder!
    var directions: Directions!
    
    var locationManager: CLLocationManager!
    var locValue: CLLocationCoordinate2D!
    
    var ref: FIRDatabaseReference!
    var appDelegate: AppDelegate!
    
    var routeDict = Dictionary<String, Any>()
    var route: Route!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userId = self.appDelegate.user?.uid
        
        //generate room number
        var roomIsSet = false
        
        //while (!roomIsSet) {
            let num1 = String(arc4random_uniform(9))
            let num2 = String(arc4random_uniform(9))
            let num3 = String(arc4random_uniform(9))
            let num4 = String(arc4random_uniform(9))
            let tempRoom = String(num1) + String(num2) + String(num3) + String(num4)
            print("checking temp room " + tempRoom)
            //self.ref.child("rooms").child(tempRoom).child("users").setValue(userId!)
        
        
            ref.child("rooms").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                print("blah " + String(snapshot.hasChild(tempRoom)))
                if (snapshot.hasChild(tempRoom) == false) {
                    self.room.text = tempRoom
                    roomIsSet = true
                    self.ref.child("rooms").child(tempRoom).child("users").setValue(userId!)
                    print("room is set to " + tempRoom)
                }
            }) { (error) in
                print(error.localizedDescription)
            }
 
            /*
            ref.child("rooms").orderByChild("ID").equalTo(tempRoom).on("value", function(snapshot) {
                var userData = snapshot.val();
                if (!userData){
                    room.text = tempRoom
                    roomIsSet = true
                    self.ref.child("rooms").child(tempRoom).child("users").setValue(userId!)
                    print("room is set to " + tempRoom)
                }
            })
            */
        //}
        
        
        
        //self.ref.child("rooms").child(room.text!).child("route").setValue(routeDict)
        
        preview.setCenter(CLLocationCoordinate2D(latitude: (route.coordinates?.first?.latitude)!,
                                                 longitude: (route.coordinates?.first?.longitude)!),
                          zoomLevel: 7, animated: false)
        
        if route.coordinateCount > 0 {
            // Convert the route’s coordinates into a polyline.
            var routeCoordinates = route.coordinates!
            let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
            
            // Add the polyline to the map and fit the viewport to the polyline.
            self.preview.addAnnotation(routeLine)
            self.preview.setVisibleCoordinates(&routeCoordinates, count: route.coordinateCount, edgePadding: .zero, animated: true)
        }
        
        
        // DO THIS AFTER THIS CONTROLLER IS DONE:
        //let viewController = NavigationUI.routeViewController(for: (routes?[0])!, directions: self.directions)
        //self.present(viewController, animated: true, completion: nil)
        
    }
    
}
