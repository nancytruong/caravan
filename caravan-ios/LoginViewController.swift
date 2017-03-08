//
//  LoginViewController.swift
//  caravan-ios
//
//  Created by Nancy on 2/21/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.textColor = UIColor.white
        // Do any additional setup after loading the view.
        
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createAccountPressed(_ sender: UIButton) {
        // check if there's text in the email & password fields
        if ((emailTextField.text != nil) && (passwordTextField.text != nil)) {
            FIRAuth.auth()?.createUser(withEmail: emailTextField.text!,
                                       password: passwordTextField.text!,
                                       completion: { (user, error) in
                                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                        appDelegate.user = user
                                        // TODO: CHECK IF VALID
                                        self.performSegue(withIdentifier: "loginToMapView", sender: self)
                                       })
        }
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        // check if there's text in the email & password fields
        if (emailTextField.text != nil && passwordTextField.text != nil) {
            FIRAuth.auth()?.signIn(withEmail: emailTextField.text!,
                                       password: passwordTextField.text!,
                                       completion: { (user, error) in
                                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                        appDelegate.user = user
                                        if (error != nil) {
                                            print((error?.localizedDescription)! + " ugh")
                                            self.errorLabel.textColor = UIColor.red
                                            //self.errorLabel.text = "ugh"
                                            self.errorLabel.text = error?.localizedDescription
                                        } else {
                                            self.performSegue(withIdentifier: "loginToMapView", sender: self)
                                        }
            })
        }
    }
    
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginViewController: UITextFieldDelegate {
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
