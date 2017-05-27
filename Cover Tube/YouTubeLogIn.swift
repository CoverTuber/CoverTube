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


// MARK: OAuth2 constants
let keychain = KeychainSwift()

let reversedClientIDURL = URL(string: reversedClientID)

let iOSURL = URL(string: iOSURL_scheme)

let OAauth2_Auth_State_Key = "Oauth2AuthState"

/* Checks whether user is logged in or not */
func isUserLoggedIn () -> Bool {
    if let authState = getAuthState() {
        print("authState = \(authState)")
        return true // isAuthTokenActive()
    } else {
        return false
    }
}

/* Checks whether auth token expired or not. */
// TODO:
func isAuthTokenActive () -> Bool{
    if let authState = getAuthState() {
        if authState.lastTokenResponse == nil { return false }
        if authState.lastTokenResponse!.accessTokenExpirationDate == nil { return false }
        print("tokkk = \(String(describing: authState.lastAuthorizationResponse.accessToken))")
        let accessTokenExpirationDate = authState.lastTokenResponse!.accessTokenExpirationDate!
        
        let now = Date()
        let remainingTime = now.timeIntervalSince(accessTokenExpirationDate)
        print("remainingTime = \(remainingTime)")
        if remainingTime < -5 {
            /* 5 seconds remaining */
            return true
        } else {
            return false
        }
    } else {
        // no authState
        return false
    }
}

/* returns oauth2 token string if exists */
func getAuth2AccessTokenString () -> String? {
    if let authState = getAuthState() {
        return authState.lastTokenResponse?.accessToken
    } else {
        return nil
    }
}

/*
 Logs into youtube
 https://developers.google.com/identity/protocols/OAuth2UserAgent
 Step 2. Redirect to Google's OAuth2 server
 Step 3. Google prompts user for consent
 */
func redirectToOAuth2Server ()
{
    let snapchatSwipeContainerVC = AppDelegate.getSnapchatSwipeContainerVC()
    if snapchatSwipeContainerVC == nil { return }
    
    currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                      presenting: snapchatSwipeContainerVC!,
                                                      callback: { (authState : OIDAuthState?,
                                                        error : Error?) in
                                                        /* Step 4: Handle the OAuth 2.0 server response */
                                                        
                                                        if authState != nil
                                                        {
                                                            handleRetrievedAuthState(authState: authState!)
                                                            validateToken()
                                                        }
                                                        else
                                                        {
                                                            print("login error : \(error!.localizedDescription)")
                                                            keychain.delete(OAauth2_Auth_State_Key)
                                                        }
    })
}

let baseURLString = "https://www.googleapis.com/youtube/v3"
let likeURLString = "\(baseURLString)/videos/rate"

/* 
 Step 4: Handle the OAuth 2.0 server response
         if authState is not nil
 */
func handleRetrievedAuthState (authState : OIDAuthState)
{
    print("authState >> \(authState)")
    print("authState.lastTokenResponse = \(authState.lastTokenResponse)")
    let data = NSKeyedArchiver.archivedData(withRootObject: authState)
    keychain.set( data, forKey: OAauth2_Auth_State_Key )
    
    let refreshToken = authState.refreshToken
    
    print("authState.lastTokenResponse = \(String(describing: authState.lastTokenResponse))")
    
    print("got authroization. token = \(authState.lastTokenResponse?.accessToken)")
    let now = Date()
    let accessTokenExpirationDate = authState.lastTokenResponse!.accessTokenExpirationDate
    let timeInterval = now.timeIntervalSince(accessTokenExpirationDate!)
    print("see freshly retrieved token's time interval since now = \(timeInterval)")
    
    
    // updateRootViewController()
}

/* returns AuthState if previously retrieved successfully. */
func getAuthState() -> OIDAuthState? {
    let data = keychain.getData(OAauth2_Auth_State_Key)
    if data == nil { return nil }
    else {
        let authState = NSKeyedUnarchiver.unarchiveObject(with: data!) as! OIDAuthState
        print("decoded authState = \(authState)")
        return authState
    }
}



/* logs user out */
func logout() {
    keychain.delete(OAauth2_Auth_State_Key )
}

/*
 Validate user's token
 https://developers.google.com/identity/protocols/OAuth2UserAgent#handlingresponse
 Step 5: Validate the user's token
 */
func validateToken()
{
    let accessTokenKey = getAuth2AccessTokenString ()
    if accessTokenKey == nil { return }
    
    let validateRequestURLString
        = "https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=\(accessTokenKey!)"
    
    let validateRequestURL = URL(string: validateRequestURLString)!
    
    var request = URLRequest(url : validateRequestURL)
    request.httpMethod = "GET"
    
    let task = URLSession.shared.dataTask(with: request)
    { (data : Data?, urlResponse : URLResponse?, error : Error?) in
        if error == nil {
            let dataStr = String(data : data!,
                                 encoding : String.Encoding.utf8)
            
            print("val dataStr = \(String(describing: dataStr))")
            YouTube.shared.populatePlaylists()
            YouTube.shared.popularVideos()
        } else {
            print("validate : error = \(error?.localizedDescription)")
        }
    }
    task.resume()
}


/*
 Refresh token
 */


/* returns whether refresh token exists or not */
func isRefreshTokenStored() -> Bool {
    if let authState = getAuthState() {
        if let refreshToken = authState.refreshToken {
            return !refreshToken.isEmpty
        } else {
            return false
        }
    } else {
        return false
    }
}
