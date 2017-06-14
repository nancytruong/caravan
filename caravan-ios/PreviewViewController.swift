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
    var route: Route?
    
    var roomInput: String = ""
    
    var locVal: CLLocationCoordinate2D!
    
    deinit {
        self.ref.child("rooms").removeAllObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userId = self.appDelegate.user?.uid

        if (roomInput.isEmpty) {
            //generate room number
            var roomIsSet = false
            var roomArr = [String]()
            print("heeellooossss")
            //ref.child("rooms").observeSingleEvent(of: .value, with: { (snapshot) in print("whut?")})
            ref.child("roomKeys").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
                let enumerator = snapshot.children
                while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                    roomArr.append(String(describing: rest.key))
                }
                while (!roomIsSet) {
                    print("in the while")
                    let num1 = String(arc4random_uniform(9))
                    let num2 = String(arc4random_uniform(9))
                    let num3 = String(arc4random_uniform(9))
                    let num4 = String(arc4random_uniform(9))
                    let tempRoom = String(num1) + String(num2) + String(num3) + String(num4)
                    
                    if (!roomArr.contains(tempRoom)) {
                        self.room.text = tempRoom
                        roomIsSet = true
                    
                        let childUpdates = ["/rooms/\(tempRoom)/finish": [self.route!.coordinates?.last?.latitude, self.route!.coordinates?.last?.longitude],
                                            "/users/\(userId!)/location": [self.route!.coordinates?.first?.latitude, self.route!.coordinates?.first?.longitude],
                                            "/rooms/\(tempRoom)/users": userId] as [String : Any]
                        self.ref.child("roomKeys").childByAutoId().setValue(tempRoom);
                        self.ref.updateChildValues(childUpdates)
                    }
                }
                
                self.preview.setCenter(CLLocationCoordinate2D(latitude: (self.route?.coordinates?.first?.latitude)!,
                                                         longitude: (self.route?.coordinates?.first?.longitude)!),
                                  zoomLevel: 7, animated: false)
                
                if self.route!.coordinateCount > 0 {
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = self.route!.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: self.route!.coordinateCount)
                    
                    // Add the polyline to the map and fit the viewport to the polyline.
                    self.preview.addAnnotation(routeLine)
                    self.preview.setVisibleCoordinates(&routeCoordinates, count: self.route!.coordinateCount, edgePadding: .zero, animated: true)
                }
            }) { (error) in
                print(error.localizedDescription)
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
                print("here is temp")
                print(temp)
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
                        self.route = tempRoute
                    }
                    
                    self.preview.setCenter(CLLocationCoordinate2D(latitude: self.locVal.latitude, longitude: self.locVal.longitude), zoomLevel: 7, animated: false)
                    
                    if ((self.route?.coordinateCount)! > 0) {
                        // Convert the route’s coordinates into a polyline.
                        var routeCoordinates = self.route?.coordinates!
                        let routeLine = MGLPolyline(coordinates: routeCoordinates!, count: (self.route?.coordinateCount)!)
                        
                        // Add the polyline to the map and fit the viewport to the polyline.
                        self.preview.addAnnotation(routeLine)
                        self.preview.setVisibleCoordinates(routeCoordinates!, count: (self.route?.coordinateCount)!, edgePadding: .zero, animated: true)
                    }
                }
                print("wheee")
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }
        print("afterrrrr")
        // DO THIS AFTER THIS CONTROLLER IS DONE:
        //let viewController = NavigationUI.routeViewController(for: (routes?[0])!, directions: self.directions)
        //self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func startNav(_ sender: Any) {
        // call the segue to start the navigation controller
        //TODO: check if currRoute is nill or not
        let viewController = NavigationUI.routeViewController(for: self.route!, directions: self.directions)
        self.present(viewController, animated: true, completion: nil)
        // TODO: chck if room.text is valid room # before calling this
        ref.child("rooms").child(room.text!).child("users").observeSingleEvent(of: .value,
                                                                              with:
            { (snapshot) in
                var map = viewController.mapView
                var tempDict = snapshot.value as? NSDictionary
                var roomUsers = Set(tempDict!.allValues as! [String])
                dump(roomUsers)
                //testMultAnnotations(Array(roomUsers))
                // add all the locations of the users?
                var userCoords = NSDictionary()
                for user in roomUsers {
                    self.ref.child("users").child(user).child("location").observe(FIRDataEventType.value,
                        with: {(snapshot) in
                            print("location updated!")
                            userCoords.setValue(CLLocationCoordinate2D(latitude: 0, longitude: 0), forKey: user)
                        })
                }
                dump(userCoords)
                print("woootttt")
            })
        // do an observe single event to get all users in room
        // attach an observe thingy to each user coord
        // in the callback for the second observe call, update the annotations
    }
    /*
    func testMultAnnotations(coords: [CLLocationCoordinate2D]) {
        let coords = [CLLocationCoordinate2D(latitude: 35.301355, longitude: -120.660459),
                      CLLocationCoordinate2D(latitude: 35.302355, longitude: -120.670459),
                      CLLocationCoordinate2D(latitude: 35.300355, longitude: -120.680459),]
        for coordinate in coords {
            let point = UserLocAnnotation(coordinate: coordinate)
            point.title = "\(coordinate.latitude), \(coordinate.longitude)"
            pointAnnotations.append(point)
        }
        
        mapView.addAnnotations(pointAnnotations)
    }*/

    @IBAction func testButton(_ sender: Any) {
        let userId = appDelegate.user?.uid
        
        print("sending long: \(locValue.longitude) lat: \(locValue.latitude)")
        // TODO: the room # will need to be changed
        ref.child("rooms").child("3382").child("users").child(userId!).setValue([locValue.latitude, locValue.longitude])
        print("done!")
    }
    
    @IBAction func getLocation(_ sender: Any) {
        let userId = "BbQD2VoTHrQ4XszHJswrnZ3MeMk1" //change this hard code later
        
        ref.child("rooms").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let valueArr = snapshot.value as? NSDictionary
            print("waows")
            //let longitude = value?["longitude"] as? Float ?? 0.0
            //let latitude = value?["latitude"] as? Float ?? 0.0
            //print("FROM DB: long", valueArr![0], "& lat", valueArr![1])
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
 }
