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
    var currRoute: Route?
    
    var roomInput: String = ""
    
    var locVal: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userId = self.appDelegate.user?.uid

        if (roomInput.isEmpty) {
            //generate room number
            var roomIsSet = false
            var roomArr = [String]()
        
            ref.child("rooms").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                let enumerator = snapshot.children
                while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                    roomArr.append(String(describing: rest.key))
                }
                while (!roomIsSet) {
                    let num1 = String(arc4random_uniform(9))
                    let num2 = String(arc4random_uniform(9))
                    let num3 = String(arc4random_uniform(9))
                    let num4 = String(arc4random_uniform(9))
                    let tempRoom = String(num1) + String(num2) + String(num3) + String(num4)
                    
                    if (!roomArr.contains(tempRoom)) {
                        self.room.text = tempRoom
                        roomIsSet = true
                    
                        let childUpdates = ["/rooms/\(tempRoom)/finish": [self.route.coordinates?.last?.latitude, self.route.coordinates?.last?.longitude],
                                            "/rooms/\(tempRoom)/start": [self.route.coordinates?.first?.latitude, self.route.coordinates?.first?.longitude],
                                            "/rooms/\(tempRoom)/users": userId] as [String : Any]
                        self.ref.updateChildValues(childUpdates)
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
            }
            
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
        }
        else {
            room.text = roomInput
            
            
            ref.child("rooms").child(roomInput).child("finish").observeSingleEvent(of: .value, with: { (snapshot) in

                var temp = [CLLocationDegrees]()
                if let coord = snapshot.value as? NSArray{
                    for i in 0..<coord.count {
                        temp.append(coord[i] as! CLLocationDegrees)
                    }
                }
                
                let dest = CLLocationCoordinate2D(latitude: temp[0], longitude: temp[1])
                
                let waypoints = [
                    Waypoint(
                        coordinate: self.locVal,
                        name: "Current Location"
                    ),
                    Waypoint(
                        coordinate: dest,
                        name: "Destination" //should we change to real destination name?
                    ),
                    ]
                let options = RouteOptions(waypoints: waypoints, profileIdentifier: MBDirectionsProfileIdentifier.automobile)
                options.includesSteps = true
                options.includesAlternativeRoutes = true;
                _ = self.directions.calculate(options) { (waypoints, routes, error) in
                    guard error == nil else {
                        print("Error calculating directions: \(error!)")
                        return
                    }
                    if let tempRoute = routes?.first {
                        let currRoute = tempRoute
                    }
                }
                
                
                self.preview.setCenter(CLLocationCoordinate2D(latitude: self.locVal.latitude, longitude: self.locVal.longitude), zoomLevel: 7, animated: false)
                //IDK HOW TO FIX THISSSSS
                /*
                if ((self.currRoute?.coordinateCount)! > 0) {
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = self.currRoute?.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: self.currRoute?.coordinateCount)

                    // Add the polyline to the map and fit the viewport to the polyline.
                    self.preview.addAnnotation(routeLine)
                    self.preview.setVisibleCoordinates(&routeCoordinates, count: self.currRoute?.coordinateCount, edgePadding: .zero, animated: true)
                }
                */
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }
    }
    
    @IBAction func startNav(_ sender: Any) {
        // call the segue to start the navigation controller
        let viewController = NavigationUI.routeViewController(for: route, directions: self.directions)
        self.present(viewController, animated: true, completion: nil)
    }
}
