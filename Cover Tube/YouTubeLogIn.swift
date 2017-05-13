//
//  YouTubeLogIn.swift
//  Cover Tube
//
//  Created by June Suh on 5/12/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation
import AppAuth

let clientID = "426605566501-i5urvqr6npalrt3niffmo96rard4rf1n.apps.googleusercontent.com"
let reversedClientID = "com.googleusercontent.apps.426605566501-i5urvqr6npalrt3niffmo96rard4rf1n"
let reversedClientIDURL = URL(string: reversedClientID)

let iOSURL_scheme = "com.googleusercontent.apps.426605566501-i5urvqr6npalrt3niffmo96rard4rf1n"
let iOSURL = URL(string: iOSURL_scheme)

let localHostURL = URL(string: "http://127.0.0.1")


/*
 Obtaining OAuth 2.0 access tokens
 step 1. Send a request to Google's OAuth 2.0 server https://accounts.google.com/o/oauth2/v2/auth.
 This endpoint handles active session lookup, authenticates the user, and obtains user consent. The endpoint is only accessible over SSL, and it refuses HTTP (non-SSL) connections.
 
 @param - client_id, redirect_uri
 
 */
