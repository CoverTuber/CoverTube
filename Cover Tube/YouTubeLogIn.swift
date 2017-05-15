//
//  YouTubeLogIn.swift
//  Cover Tube
//
//  Created by June Suh on 5/12/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation
import AppAuth
import KeychainSwift

let keychain = KeychainSwift()

let reversedClientIDURL = URL(string: reversedClientID)

let iOSURL = URL(string: iOSURL_scheme)

let OAuth2_Token_Key = "OAuth2Token"

/* Checks whether user is logged in or not */
func isUserLoggedIn () -> Bool {
    let auth2TokenStr = getAuth2TokenString()
    if auth2TokenStr == nil { return false }
    else {
        return !auth2TokenStr!.isEmpty
    }
}

/* returns oauth2 token string if exists */
func getAuth2TokenString () -> String? {
    return keychain.get(OAuth2_Token_Key)
}

/* saves parameter string as OAuth2 string */
func saveAuth2Token (tokenString : String) {
    keychain.set(tokenString, forKey: OAuth2_Token_Key)
}

/* updates root view controller based on logged in or not. */
func updateRootViewController ()
{
    let appDelegate = UIApplication.shared.delegate
    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
    
    if appDelegate == nil { return }
    if appDelegate!.window == nil { return }
    if appDelegate!.window! == nil { return }
    
    let window = appDelegate!.window!!
    
    let currentRootVC = window.rootViewController
    
    if isUserLoggedIn()
    {
        let swipeContainerVC = storyBoard.instantiateViewController(withIdentifier: "SwipeContainerVC")
        
        if currentRootVC == nil {
            window.rootViewController = swipeContainerVC
        } else if !(window.rootViewController is SwipeContainerViewController) {
            window.rootViewController = swipeContainerVC
        } else {
            // already swipeContainerVC is root
        }
    }
    else // user is not logged in
    {
        let loginVC = storyBoard.instantiateViewController(withIdentifier: "VC")
        
        if currentRootVC == nil {
            window.rootViewController = loginVC
        }
        else
        {
            if !(window.rootViewController! is ViewController) {
                window.rootViewController = loginVC
            }
            else {
                // already loginVC is root
            }
            
        }
    }
}

/* logs user out */
func logout() {
    keychain.delete(OAuth2_Token_Key)
}
