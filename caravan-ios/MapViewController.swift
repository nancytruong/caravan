//
//  ViewController.swift
//  caravan-ios
//
//  Created by Nancy on 1/25/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import FirebaseDatabase
import FirebaseAuth
import MapboxGeocoder

class MapViewController: UIViewController {
    
    // mapbox
    @IBOutlet var mapView: MGLMapView!
    let geocoder = Geocoder.shared
    let directions = Directions.shared
    
    // firebase
    var ref: FIRDatabaseReference!
    
    let locationManager = CLLocationManager()
    var locValue: CLLocationCoordinate2D!
    
    var menuView: UIView?
    var isMenuOpen: Bool = false
    let menuSize: CGFloat = 0.8
    var topBuffer: CGFloat?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // check if valid user, if no go to login
        if (appDelegate.user == nil){
            self.performSegue(withIdentifier: "showLogin", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        topBuffer = (self.navigationController?.navigationBar.frame.height)! + UIApplication.shared.statusBarFrame.size.height
        
        // set up menu
        menuView = UITableView.init(frame: CGRect.init(x: -(self.view.frame.width*menuSize),
                                                       y: topBuffer!,
                                                       width: self.view.frame.width*menuSize,
                                                       height: (self.view.frame.height-(self.navigationController?.navigationBar.frame.height)!)))
        self.view.addSubview(menuView!)
        //var button = UIButton.init(frame: CGRect.init(x: menuView?.frame., y: 10, width: <#T##Double#>, height: <#T##Double#>))
        
        // create & add the screen edge gesture recognizer to open the menu
        let edgePanGR = UIScreenEdgePanGestureRecognizer(target: self,
                                                         action: #selector(self.handleEdgePan(recognizer:)))
        edgePanGR.edges = .left
        self.view.addGestureRecognizer(edgePanGR)
        
        //create & add the tap gesutre recognizer to close the menu
        let tapGR = UITapGestureRecognizer(target: self,
                                           action: #selector(self.handleTap(recognizer:)))
        self.view.addGestureRecognizer(tapGR)
    
        // initialize reference to DB
        ref = FIRDatabase.database().reference()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
    }
    
    @IBAction func signOutPressed(_ sender: UIButton) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            print("YAY SIGNOUT")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MapViewController: MGLMapViewDelegate {
    
    // get a route object and also draw the route on the map
    func mapboxRoute() {
        let waypoints = [
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047),
                name: "Mapbox"
            ),
            Waypoint(
                coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365),
                name: "White House"
            ),
            ]
        let options = RouteOptions(waypoints: waypoints, profileIdentifier: MBDirectionsProfileIdentifier.automobile)
        options.includesSteps = true
        
        _ = directions.calculate(options) { (waypoints, routes, error) in
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }
            
            if let route = routes?.first, let leg = route.legs.first {
                print("Route via \(leg):")
                
                let distanceFormatter = LengthFormatter()
                let formattedDistance = distanceFormatter.string(fromMeters: route.distance)
                
                let travelTimeFormatter = DateComponentsFormatter()
                travelTimeFormatter.unitsStyle = .short
                let formattedTravelTime = travelTimeFormatter.string(from: route.expectedTravelTime)
                
                print("Distance: \(formattedDistance); ETA: \(formattedTravelTime!)")
                
                for step in leg.steps {
                    print("\(step.instructions)")
                    let formattedDistance = distanceFormatter.string(fromMeters: step.distance)
                    print("— \(formattedDistance) —")
                }
                
                
                
                if route.coordinateCount > 0 {
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = route.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
                    
                    // Add the polyline to the map and fit the viewport to the polyline.
                    self.mapView.addAnnotation(routeLine)
                    self.mapView.setVisibleCoordinates(&routeCoordinates, count: route.coordinateCount, edgePadding: .zero, animated: true)
                }
                
                
            }
        }
    }
    
    func annotation() {
        let point = MGLPointAnnotation()
        point.coordinate = CLLocationCoordinate2D(latitude: 35.301355, longitude: -120.660459)
        point.title = "California Polytechnic San Luis Obispo"
        point.subtitle = "1 Grand Ave San Luis Obispo CA, U.S.A"
        mapView.addAnnotation(point)
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always try to show a callout when an annotation is tapped.
        return true
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    @IBAction func sendLocationPressed(_ sender: Any) {
        //let username = "Spud"
        //ref.child("users/1/username").setValue(username)
        print("sending long: \(locValue.longitude) lat: \(locValue.latitude)")
        ref.child("users/1/coord/longitude").setValue(locValue.longitude)
        ref.child("users/1/coord/latitude").setValue(locValue.latitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locValue = (manager.location?.coordinate)!
    }
}

extension MapViewController: UIGestureRecognizerDelegate {
    // GESTURE RECOGNIZERS
    func handleEdgePan(recognizer: UIScreenEdgePanGestureRecognizer) {
        // open animation of menu
        self.openMenu()
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        // check if menu is expanded & if tap is in correct area
        let point = recognizer.location(in: self.view)
        if (isMenuOpen == true && point.x >= (self.view.frame.width*menuSize)){
            // close the menu
            self.closeMenu()
        }
    }
    
    // ANIMATIONS
    func closeMenu() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                       animations: {
                        self.menuView!.frame.origin.x = -(self.view.frame.width*self.menuSize)
        },
                       completion: { finished in
                        self.isMenuOpen = false
        }
        )
    }
    
    func openMenu() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                       animations: {
                        self.menuView!.frame.origin.x = CGPoint.zero.x
        },
                       completion: { finished in
                        self.isMenuOpen = true
        }
        )
    }
    
    // BUTTON ACTION
    @IBAction func menuTapped(_ sender: UIButton) {
        openMenu()
        isMenuOpen = true
    }
}

