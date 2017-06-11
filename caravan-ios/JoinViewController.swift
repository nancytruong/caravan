//
//  JoinViewController.swift
//  caravan-ios
//
//  Created by Renee Liu on 6/9/17.
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

class JoinViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var roomInput: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    var ref: FIRDatabaseReference!
    var appDelegate: AppDelegate!
    
    var geocoder: Geocoder!
    var directions: Directions!
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomInput.delegate = self
        
        roomInput.keyboardType = UIKeyboardType.numberPad
        
        errorLabel.textColor = UIColor.white
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        let maxLength = 4
        let currentString: NSString = roomInput.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    @IBAction func done(_ sender: Any) {
        
        var roomArr = [String]()
        
        ref.child("rooms").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                roomArr.append(String(describing: rest.key))
            }
            if (roomArr.contains(self.roomInput.text!)) {
                let locValue:CLLocationCoordinate2D = self.locationManager.location!.coordinate

                let userId = self.appDelegate.user?.uid
                self.ref.child("rooms").child(self.roomInput.text!).child("users").child(userId!).setValue(
                [locValue.latitude,
                locValue.longitude])
 
                self.performSegue(withIdentifier: "showDone", sender: self)
            }
            else {
                //print error message on screen
                self.errorLabel.textColor = UIColor.red
                self.errorLabel.text = "ERROR: invalid room number"
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showDone" {
            let controller = segue.destination as! PreviewViewController
            
            controller.ref = ref
            controller.appDelegate = appDelegate
            controller.locationManager = locationManager
            controller.directions = directions
            controller.geocoder = geocoder
            controller.roomInput = roomInput.text!
            controller.locVal = locationManager.location!.coordinate
        }
    }


}
