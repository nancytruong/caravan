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
            var newDict = Dictionary<String, Any>()
            var stepsDict = [Dictionary<String, Any>]()
            var legsDict = [Dictionary<String, Any>]()
            var intersectionsDict = [Dictionary<String, Any>]()
            
            var legDict = Dictionary<String, Any>()
            var legSourceDict = Dictionary<String, Any>()
            var legDestinationDict = Dictionary<String, Any>()
            var stepDict = Dictionary<String, Any>()
            var intersectionDict = Dictionary<String, Any>()
            
            var approachLanes: [String] = []
            
            if let route = routes?.first, let leg = route.legs.first {
                for leg in route.legs {
                    legDict["distance"] = leg.distance
                    legDict["name"] = leg.name
                    legDict["expectedTravelTime"] = leg.expectedTravelTime
                    legDict["description"] = leg.description
    
                    legDict["profileIdentifier"] = leg.profileIdentifier

                    legSourceDict["name"] = leg.source.name
                    legSourceDict["location"] = [leg.source.coordinate.latitude, leg.source.coordinate.longitude]
                    legDestinationDict["name"] = leg.destination.name
                    legDestinationDict["location"] = [leg.destination.coordinate.latitude, leg.destination.coordinate.longitude]
                    
                    legDict["source"] = legSourceDict
                    legDict["destination"] = legDestinationDict
                    
                    for step in leg.steps {
                        stepDict["codes"] = step.codes ?? [""]
                        stepDict["coordinateCount"] = step.coordinateCount
                        
                        var temp: [[CLLocationDegrees]] = []
                        for coord in step.coordinates! {
                            temp.append([coord.latitude, coord.longitude])
                        }
                        stepDict["coordinates"] = temp
                        
                        stepDict["description"] = step.description
                        stepDict["destinationCodes"] = step.destinationCodes ?? [""]
                        stepDict["destinations"] = step.destinations ?? [""]
                        stepDict["distance"] = step.distance
                        
                        stepDict["instructions"] = step.instructions
                        stepDict["finalHeading"] = step.finalHeading
                        stepDict["maneuverLocation"] = [step.maneuverLocation.latitude, step.maneuverLocation.longitude]
                        
                        stepDict["maneuverType"] = step.maneuverType?.description
                        stepDict["maneuverDirection"] = step.maneuverDirection?.description
                        
                        for intersection in step.intersections! {
                            
                            if let lanes = intersection.approachLanes {
                                for lane in lanes {
                                    approachLanes.append(lane.indications.description)
                                }
                            }
                            intersectionDict["approachLanes"] = approachLanes
                            approachLanes.removeAll()
                            intersectionDict["headings"] = intersection.headings //[CLLocationDirection]
                            
                            var output: [Int] = [];
                            var args = intersection.usableApproachLanes?.makeIterator();
                            while let arg = args?.next() {
                                output.append(arg)
                            }
                            
                            if output.count > 0 {
                                intersectionDict["usableApproachLanes"] = output
                            }
                            else {
                                intersectionDict["usableApproachLanes"] = [-1]
                            }
                            
                            var output2: [Int] = [];
                            var args2 = intersection.outletIndexes.makeIterator();
                            while let arg = args2.next() {
                                output2.append(arg)
                            }
                            intersectionDict["outletIndexes"] = output2

                            intersectionsDict.append(intersectionDict)
                            intersectionDict.removeAll()
                        }
                        stepDict["intersections"] = intersectionsDict
                        
                        stepsDict.append(stepDict)
                        stepDict.removeAll()
                    }
                    legDict["steps"] = stepsDict
                    stepsDict.removeAll()
                    legsDict.append(legDict)
                    legDict.removeAll()
                    
                }
                
                newDict["duration"] = route.expectedTravelTime
                newDict["distance"] = route.distance
                newDict["profileIdentifier"] = route.profileIdentifier
                
                var coordinateArray: [[CLLocationDegrees]] = []
                for coord in route.coordinates! {
                    coordinateArray.append([coord.latitude, coord.longitude])
                }
                newDict["geometry"] = coordinateArray
                
                newDict["legs"] = legsDict
                
            }
            
            let userId = self.appDelegate.user?.uid
            self.ref.child("users").child(userId!).child("route").setValue(newDict)
            
        
            let viewController = NavigationUI.routeViewController(for: (routes?[0])!, directions: self.directions)
            self.present(viewController, animated: true, completion: nil)
        }
        
        //print(cell?.textLabel?.text)
        //print("search results: " + searchResults[indexPath.row].qualifiedName)
        //print(searchResults[indexPath.row].location.coordinate)
    }
}
