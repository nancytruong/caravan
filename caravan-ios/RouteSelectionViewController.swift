//
//  RouteSelectionViewController.swift
//  caravan-ios
//
//  Created by Sara Edmonds on 5/23/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import MapboxNavigation
import MapboxGeocoder
import FirebaseDatabase
import FirebaseAuth

class RouteSelectionViewController: UITableViewController {
    
    var geocoder: Geocoder!
    var directions: Directions!
    
    var locationManager: CLLocationManager!
    var locValue: CLLocationCoordinate2D!
    
    var ref: FIRDatabaseReference?
    var appDelegate: AppDelegate!
    
    var routes: [Route]!
    var selectedRoute: Route?
    
    deinit {
        self.ref?.child("rooms").removeAllObservers()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("routes.count:", routes.count);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
        print("want to change the route selection cell")
        if (indexPath.row < routes.count) {
            print(routes[indexPath.row].description)
            cell.textLabel?.text = routes[indexPath.row].description
        } else {
            cell.textLabel?.text = "nothing"
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRoute = routes[indexPath.row]
        self.performSegue(withIdentifier: "showPreview", sender: self)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showPreview" {
            let controller = segue.destination as! PreviewViewController
            
            controller.ref = ref
            controller.appDelegate = appDelegate
            controller.locationManager = locationManager
            controller.directions = directions
            controller.geocoder = geocoder
            controller.locValue = locValue
            controller.route = selectedRoute
        }
    }
    

}
