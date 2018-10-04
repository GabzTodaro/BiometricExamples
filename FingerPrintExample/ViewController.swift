//
//  ViewController.swift
//  FingerPrintExample
//
//  Created by Gabriel Todaro on 04/10/18.
//  Copyright © 2018 Todaro. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    
    var faceId : Bool = false
    var biometricName : String = "Touch ID"
    
    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.authenticateUserUsingTouchId()
        
    }
    
    // Login button and authentication
    @IBAction func login(_ sender: Any) {
        var login = String()
        var password = String()
        
        if let safeLogin = loginField.text {
            if safeLogin.isEmpty {
                print("Invalid login")
                return
            }
            login = safeLogin
        }
        
        if let safePassword = passwordField.text {
            if safePassword.isEmpty {
                print("Invalid password")
                return
            }
            password = safePassword
        }
        
        self.saveAccountDetailsToKeychain(account: login, password: password)
        self.showPopupWithMessage(message: "First login realized. Kill the app and try again with biometric. =)")
        
    }
    fileprivate func authenticateUserFor(password: String) {
        print("Password is: \(password)")
        self.showPopupWithMessage(message: "Everything works! Congratulations =D")
    }
    fileprivate func authenticateUserUsingTouchId() {
        
        let context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            faceId = context.biometryType == LABiometryType.faceID
            
            biometricName = faceId ? "Face ID" : biometricName
            
            self.evaulateTouchIdAuthenticity(context: context)
        }
    }
    func evaulateTouchIdAuthenticity(context: LAContext) {
        guard let lastAccessedUserName = UserDefaults.standard.object(forKey: "lastAccessedUserName") as? String else { return }
        
        // Need to put Privacy - Face Id on Info.plist for use Face ID.
        let authReason = "Please use \(biometricName) to sign in with the \(lastAccessedUserName) user."
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: authReason) { (authSuccessful, authError) in
            if authSuccessful {
                DispatchQueue.main.async {
                    self.loadPasswordFromKeychainAndAuthenticateUser(lastAccessedUserName)
                }
            } else {
                if let error = authError as? LAError {
                    DispatchQueue.main.async {
                        self.showError(error: error)
                    }
                }
            }
        }
    }
    
    // Keychain stuff
    fileprivate func saveAccountDetailsToKeychain(account: String, password: String) {
        //        guard account.isEmpty, password.isEmpty else { return }
        UserDefaults.standard.set(account, forKey: "lastAccessedUserName")
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
        do {
            try passwordItem.savePassword(password)
        } catch {
            print("Error saving password")
        }
    }
    fileprivate func loadPasswordFromKeychainAndAuthenticateUser(_ account: String) {
        guard !account.isEmpty else { return }
        let passwordItem = KeychainPasswordItem(service:   KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
        do {
            let storedPassword = try passwordItem.readPassword()
            self.authenticateUserFor(password: storedPassword)
        } catch KeychainPasswordItem.KeychainError.noPassword {
            print("No saved password")
        } catch {
            print("Unhandled error")
        }
    }
    
    // Handle stuffs
    func showError(error: LAError) {
        var message: String = ""
        switch error.code {
        case LAError.authenticationFailed:
            message = "Authentication was not successful because the user failed to provide valid credentials. Please enter password to login."
            break
        case LAError.userCancel:
            message = "Authentication was canceled by the user"
            break
        case LAError.userFallback:
            message = "Authentication was canceled because the user tapped the fallback button"
            break
        case LAError.biometryNotEnrolled:
            message = "Authentication could not start because Touch ID has no enrolled fingers."
            break
        case LAError.passcodeNotSet:
            message = "Passcode is not set on the device."
            break
        case LAError.systemCancel:
            message = "Authentication was canceled by system"
            break
        default:
            message = error.localizedDescription
            break
        }
        self.showPopupWithMessage(message: message)
    }
    func showPopupWithMessage(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.show(alert, sender: nil)
    }
    
}

