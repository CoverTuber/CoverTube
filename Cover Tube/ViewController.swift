//
//  ViewController.swift
//  Cover Tube
//
//  Created by June Suh on 3/2/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit
import AppAuth

/*
 https://github.com/openid/AppAuth-iOS
 */
var currentAuthorizationFlow : OIDAuthorizationFlowSession? = nil
var youTubeAuthState : OIDAuthState? = nil
let request = OIDAuthorizationRequest(configuration: configuration,
                                      clientId: clientID,
                                      clientSecret: nil,
                                      scopes: [OIDScopeOpenID, OIDScopeProfile],
                                      redirectURL: localHostURL!, // NOTE: Not sure!!!
                                      responseType: OIDResponseTypeCode,
                                      additionalParameters: nil)

class ViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                          presenting: self,
                                                          callback: { (authState : OIDAuthState?,
                                                            error : Error?) in
                                                            if authState != nil
                                                            {
                                                                print("got authroization. token = \(authState?.lastTokenResponse?.accessToken)")
                                                                youTubeAuthState = authState
                                                            } else {
                                                                print("error : \(error!.localizedDescription)")
                                                                youTubeAuthState = nil
                                                            }
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

