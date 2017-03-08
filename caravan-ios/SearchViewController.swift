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
import MapboxNavigationUI
import MapboxGeocoder

class SearchViewController: UIViewController {
    
    let geocoder = Geocoder.shared
    let directions = Directions.shared
    var searchResults: [GeocodedPlacemark] = []
    
    let locationManager = CLLocationManager()
    var locValue: CLLocationCoordinate2D!
    
    @IBOutlet weak var searchText: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
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
            let viewController = NavigationUI.routeViewController(for: (routes?[0])!, directions: self.directions)
            self.present(viewController, animated: true, completion: nil)
        }
        
        //print(cell?.textLabel?.text)
        //print("search results: " + searchResults[indexPath.row].qualifiedName)
        //print(searchResults[indexPath.row].location.coordinate)
    }
}
