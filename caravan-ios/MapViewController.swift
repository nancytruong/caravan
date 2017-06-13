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
import MapboxNavigation
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
    
    var menuView: MenuView?
    var isMenuOpen: Bool = false
    let menuSize: CGFloat = 0.8
    var topBuffer: CGFloat?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var panGR : UIPanGestureRecognizer?
    
    var pointAnnotations = [UserLocAnnotation] ()
    
    deinit {
        self.ref.child("rooms").removeAllObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // check if valid user, if no go to login
        if (appDelegate.user == nil) {
            //persist user auth
            FIRAuth.auth()?.addStateDidChangeListener { auth, user in
                if user == nil {
                    self.performSegue(withIdentifier: "showLogin", sender: self)
                } else if (user != nil) {
                    appDelegate.user = user
                }
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        topBuffer = (self.navigationController?.navigationBar.frame.height)! + UIApplication.shared.statusBarFrame.size.height
        
        // set up menu
        menuView = MenuView(frame: CGRect.init(x: -(self.view.frame.width*menuSize),
                                               y: 0.0,
                                               width: self.view.frame.width*menuSize,
                                               height: (self.view.frame.height)),
                            delegate: self)
        self.view.addSubview(menuView!)
        
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
        
        //mapboxRoute()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getLocationPressed(_ sender: Any) {
        mapView.removeAnnotations(pointAnnotations)
        //let userId = appDelegate.user?.uid
        // Renee: BbQD2VoTHrQ4XszHJswrnZ3MeMk1
        // Nancy: BKGE9xrtP5V6QwWYirRF3Rxpkdv2
        let userId = "BbQD2VoTHrQ4XszHJswrnZ3MeMk1" //change this hard code later
        /*
        ref.child("users").child(userId).child("coord").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let longitude = value?["longitude"] as? Float ?? 0.0
            let latitude = value?["latitude"] as? Float ?? 0.0
            print("FROM DB: long", longitude, "& lat", latitude)
            
        }) { (error) in
            print(error.localizedDescription)
        }*/
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showSearchView" {
            let controller = segue.destination as! SearchViewController
            
            controller.ref = ref
            controller.appDelegate = appDelegate
            controller.locationManager = locationManager
            controller.directions = directions
            controller.geocoder = geocoder
            controller.locValue = self.locValue
        }
        
        if segue.identifier == "showJoin" {
            let controller = segue.destination as! JoinViewController
            
            controller.ref = ref
            controller.appDelegate = appDelegate
            controller.locationManager = locationManager
            controller.directions = directions
            controller.geocoder = geocoder
        }
    }
    
}

extension MapViewController: MenuViewDelegate {
    func didClickOnLogout() {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            print("YAY SIGNOUT")
            self.performSegue(withIdentifier: "unwindToLogin", sender: self)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

extension MapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let point = annotation as? UserLocAnnotation,
            
            let image = point.image,
            let reuseIdentifier = point.reuseIdentifier {
            
            if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
                // The annotatation image has already been cached, just reuse it.
                return annotationImage
            } else {
                // Create a new annotation image.
                return MGLAnnotationImage(image: image, reuseIdentifier: reuseIdentifier)
            }
        }
        
        // Fallback to the default marker image.
        return nil
    }
    
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
                
                let viewController = NavigationUI.routeViewController(for: route, directions: self.directions)
                self.present(viewController, animated: true, completion: nil)
                
                
                /*
                if route.coordinateCount > 0 {
                    // Convert the route’s coordinates into a polyline.
                    var routeCoordinates = route.coordinates!
                    let routeLine = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
                    
                    // Add the polyline to the map and fit the viewport to the polyline.
                    self.mapView.addAnnotation(routeLine)
                    self.mapView.setVisibleCoordinates(&routeCoordinates, count: route.coordinateCount, edgePadding: .zero, animated: true)
                }*/
                
                
            }
        }
    }
    
    func testMultAnnotations() {
        let coords = [CLLocationCoordinate2D(latitude: 35.301355, longitude: -120.660459),
                      CLLocationCoordinate2D(latitude: 35.302355, longitude: -120.670459),
                      CLLocationCoordinate2D(latitude: 35.300355, longitude: -120.680459),]
        for coordinate in coords {
            let point = UserLocAnnotation(coordinate: coordinate)
            point.title = "\(coordinate.latitude), \(coordinate.longitude)"
            pointAnnotations.append(point)
        }
        
        mapView.addAnnotations(pointAnnotations)
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
        testMultAnnotations();
        
        let userId = appDelegate.user?.uid
        
        print("sending long: \(locValue.longitude) lat: \(locValue.latitude)")
        // TODO: the room # will need to be changed
        ref.child("rooms").child("3382").child("users").child(userId!).setValue([locValue.latitude, locValue.longitude])
        print("done!")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locValue = (manager.location?.coordinate)!
    }
}

extension UIPanGestureRecognizer {
    
    func isLeft(theViewYouArePassing: UIView) -> Bool {
        let v : CGPoint = velocity(in: theViewYouArePassing)
        if v.x > 0 {
            print("Gesture went right")
            return false
        } else {
            print("Gesture went left")
            return true
        }
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

