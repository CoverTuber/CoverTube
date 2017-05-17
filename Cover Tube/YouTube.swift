//
//  YouTube.swift
//  Cover Tube
//
//  Created by June Suh on 5/14/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation
import AppAuth


/*
 https://github.com/openid/AppAuth-iOS
 */

let scope = "https://www.googleapis.com/auth/youtube.force-ssl"
let scopeURL = URL(string: scope)!

var currentAuthorizationFlow : OIDAuthorizationFlowSession? = nil
var youTubeAuthState : OIDAuthState? = nil
let oauthURL = URL(string: "\(iOSURL_scheme):/oauth/callback")!

let authorizationEndpointURLString = "https://accounts.google.com/o/oauth2/v2/auth?"
// ?approval_prompt=force"
let authorizationEndpointURL = URL(string: authorizationEndpointURLString)!

let tokenEndpointString = "https://www.googleapis.com/oauth2/v4/token"
let tokenEndpointURL = URL(string: tokenEndpointString)!

let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpointURL,
                                            tokenEndpoint: tokenEndpointURL)

let request = OIDAuthorizationRequest(configuration: configuration,
                                      clientId: clientID,
                                      clientSecret: nil,
                                      scopes: [ OIDScopeOpenID, OIDScopeProfile, scope],
                                      redirectURL: oauthURL,
                                      responseType: OIDResponseTypeCode,
                                      additionalParameters: nil)

