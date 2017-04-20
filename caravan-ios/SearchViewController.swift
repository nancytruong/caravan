//
//  SearchTableViewController.swift
//  caravan-ios
//
//  Created by Nancy on 2/15/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import MapboxNavigation
import MapboxGeocoder
import FirebaseDatabase
import FirebaseAuth

class SearchViewController: UIViewController {
    
    var geocoder: Geocoder!
    var directions: Directions!
    var searchResults: [GeocodedPlacemark] = []
    
    var locationManager: CLLocationManager!
    var locValue: CLLocationCoordinate2D!
    
    @IBOutlet weak var searchText: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var ref: FIRDatabaseReference!
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchText.addTarget(self, action: #selector(searchTextChanged(_:)), for: UIControlEvents.editingChanged)
        
        //mapboxGeocoder(queryText: "Cal Poly")
        //tableView.reloadData()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapboxGeocoder(queryText: String) {
        let options = ForwardGeocodeOptions(query: queryText)
        options.allowedISOCountryCodes = ["US"]
        //options.focalLocation = locationManager.location
        options.allowedScopes = [.address, .pointOfInterest]
        
        let _ = geocoder.geocode(options,
                         completionHandler: { placemarks, attribution, error in
                            if let unwrapped = placemarks {
                                self.searchResults = unwrapped
                            } else {
                                self.searchResults = []
                            }
                            self.tableView.reloadData()
        })
    }

}

extension SearchViewController: UITextFieldDelegate {
    func searchTextChanged(_ textField: UITextField) {
        mapboxGeocoder(queryText: (textField.text ?? ""))
    }
}

extension SearchViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locValue = (manager.location?.coordinate)!
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // Configure the cell...
        if (indexPath.row < searchResults.capacity) {
            cell.textLabel?.text = searchResults[indexPath.row].qualifiedName
        } else {
            cell.textLabel?.text = ""
        }
        return cell
     }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        // have to configure options and get the directions
        let waypoints = [
            Waypoint(
                coordinate: locValue,
                name: "Current Location"
            ),
            Waypoint(
                coordinate: searchResults[indexPath.row].location.coordinate,
                name: searchResults[indexPath.row].qualifiedName
            ),
            ]
        
        let options = RouteOptions(waypoints: waypoints, profileIdentifier: MBDirectionsProfileIdentifier.automobile)
        options.includesSteps = true
        
        _ = directions.calculate(options) { (waypoints, routes, error) in
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }
            
            //sending route object to firebase
            print("on route now...")
            var newDict = Dictionary<String, Any>()
            var legDict = Dictionary<String, Any>()
            if let route = routes?.first, let leg = route.legs.first {
                
                
                for leg in route.legs {
                    print("distance: ", leg.distance)
                    //legDict["distance"] = leg.distance
                    print("name: ", leg.name)
                    print("expectedTravelTime: ", leg.expectedTravelTime)
                    print("description: ", leg.description)
                    print("destination: ", leg.destination)
                    print("pi: ", leg.profileIdentifier)
                    print("source.name: ", leg.source.name)
                    
                    
                    
                    //RouteLeg
                }
                
                
 
                /*
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
                 */
                
                newDict["duration"] = route.expectedTravelTime
                newDict["distance"] = route.distance
                newDict["profileIdentifier"] = route.profileIdentifier
                
                var coordinateArray: [[CLLocationDegrees]] = []
                for coord in route.coordinates! {
                    coordinateArray.append([coord.latitude, coord.longitude])
                }
                newDict["geometry"] = coordinateArray
                
                print(newDict)
            }
            
            let userId = self.appDelegate.user?.uid
            //self.ref.child("users").child(userId!).child("route").setValue("hi")
            self.ref.child("users").child(userId!).child("route").setValue(newDict)
            
            
            
            let viewController = NavigationUI.routeViewController(for: (routes?[0])!, directions: self.directions)
            self.present(viewController, animated: true, completion: nil)
        }
        
        //print(cell?.textLabel?.text)
        //print("search results: " + searchResults[indexPath.row].qualifiedName)
        //print(searchResults[indexPath.row].location.coordinate)
    }
}
