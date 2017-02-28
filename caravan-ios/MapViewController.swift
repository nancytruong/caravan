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

enum menuState {
    case Collapsed
    case Expanded
}

class MapViewController: UIViewController {
    
    // mapbox
    @IBOutlet var mapView: MGLMapView!
    let geocoder = Geocoder.sharedGeocoder
    let directions = Directions.shared
    
    // firebase
    var ref: FIRDatabaseReference!
    
    let locationManager = CLLocationManager()
    var locValue: CLLocationCoordinate2D!
    
    var menuView: UITableView?
    var isMenuOpen: Bool = false
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if (appDelegate.user == nil){
            self.performSegue(withIdentifier: "showLogin", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // set up menu
        menuView = UITableView.init(frame: CGRect.init(x: -400, y: 0, width: 400, height: self.view.frame.height))
        //menuView?.isUserInteractionEnabled = true
        self.view.addSubview(menuView!)
        
        // create & add the screen edge gesture recognizer to open the menu
        let edgePanGR = UIScreenEdgePanGestureRecognizer(target: self,
                                                         action: #selector(self.handleEdgePan(recognizer:)))
        edgePanGR.edges = .left
        self.view.addGestureRecognizer(edgePanGR)
        
        // create & add the pan gesture recognizer to open the menu
        let panGR = UIPanGestureRecognizer(target: self,
                                           action: #selector(self.handlePan(recognizer:)))
        self.view.addGestureRecognizer(panGR)
        
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
            self.performSegue(withIdentifier: "unwindToLogin", sender: self)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getLocationPressed(_ sender: Any) {
        
        let userId = appDelegate.user?.uid
        
        ref.child("users").child(userId!).child("coord").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let longitude = value?["longitude"] as? Float ?? 0.0
            let latitude = value?["latitude"] as? Float ?? 0.0
            print("FROM DB: long", longitude, "& lat", latitude)
            
        }) { (error) in
            print(error.localizedDescription)
        }
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
        let options = RouteOptions(waypoints: waypoints, profileIdentifier: MBDirectionsProfileIdentifierAutomobile)
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
        
        let userId = appDelegate.user?.uid
        
        print("sending long: \(locValue.longitude) lat: \(locValue.latitude)")
        ref.child("users").child(userId!).child("coord/longitude").setValue(locValue.longitude)
        ref.child("users").child(userId!).child("coord/latitude").setValue(locValue.latitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locValue = (manager.location?.coordinate)!
    }
}

extension MapViewController: UIGestureRecognizerDelegate {
    // GESTURE RECOGNIZERSs
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        // close animation of menu
        self.closeMenu()
    }

    func handleEdgePan(recognizer: UIScreenEdgePanGestureRecognizer) {
        // open animation of menu
        self.openMenu()
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        // check if menu is expanded & if tap is in correct area
        let point = recognizer.location(in: self.view)
        if (isMenuOpen == true && point.x >= 300){
            // close the menu
            self.closeMenu()
        }
    }
    
    // ANIMATIONS
    func closeMenu() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                       animations: {
                        self.menuView!.frame.origin.x = -400 // <= replace this magic number
        },
                       completion: { finished in
                        self.isMenuOpen = false
        }
        )
    }
    
    func openMenu() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut,
                       animations: {
                        self.menuView!.frame.origin.x = -100 // <= replace this magic number
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

