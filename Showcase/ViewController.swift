//
//  ViewController.swift
//  Showcase
//
//  Created by Brice Dreamer on 10/13/16.
//  Copyright © 2016 Brice Dreamer. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class ViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }


    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        /*if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
        */
        
        if let _ = KeychainWrapper.defaultKeychainWrapper().stringForKey(KEY_UID) {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }
    
    @IBAction func fbBtnPressed(sender: UIButton!) {
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logInWithReadPermissions(["email"]) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) -> Void in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult?.isCancelled == true {
                print("Cancelled Facebook login")
            } else {
                let accessToken = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                print("Successfully logged in with facebook. \(accessToken)")
                self.firebaseAuth(accessToken)
            }
        }
            
    }
    
    func firebaseAuth(credential: FIRAuthCredential) {
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user, firebaseError)in
            if firebaseError != nil {
                print("unable to authenticate with Firebase. Error \(firebaseError)")
            } else {
                print("Logged In!\(user)")
            
                if let user = user {
                    
                    let userData = ["provider": credential.provider]
                    self.completeSignIn(user.uid, userData: userData)
                }
                
                NSUserDefaults.standardUserDefaults().setValue(user!.uid, forKey: KEY_UID)
                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
            }
        })
    }
    
    @IBAction func attemptLogin(sender: UIButton!) {
        
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            
            FIRAuth.auth()?.signInWithEmail(email, password: pwd, completion: { (user, emailError) in
                if emailError == nil {
                    print("Email user authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(user.uid, userData: userData)
                    }
                    
                } else {
                    FIRAuth.auth()?.createUserWithEmail(email, password: pwd, completion: { (user, creationError) in
                        if creationError != nil {
                            self.showErrorAlert("Unable to create account with Firebase using Email", msg:"Check your Email and Password")

                        } else {
                            
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignIn(user.uid, userData: userData)
                            }
                            
                            print("Successfully created account with Firebase using Email")
                        }
                    })
                }
            })
            
        } else {
            showErrorAlert("Email and Password required", msg: "You must enter an Email and Password")
        }
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseUser(id, userData: userData)
        let keychainResult = KeychainWrapper.defaultKeychainWrapper().setString(id, forKey: KEY_UID)
        print("data saved to keychain\(keychainResult)")
        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }


}

