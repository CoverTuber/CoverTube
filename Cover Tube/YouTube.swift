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


let likeBaseURLString = "https://www.googleapis.com/youtube/v3/videos/rate"


/*
 Likes the video using OAuth2 token
 */
func likeVideo (videoID : String)
{
    if getAuth2AccessTokenString () == nil {
        print("OAuth2TokenKey is empty")
        // MARK: Go to login view
        updateRootViewController()
        return
    }
    
    let likeURLString = "\(likeBaseURLString)?id=\(videoID)&rating=like"
    let likeURL = URL(string: likeURLString)!
    var request = URLRequest(url: likeURL)
    request.httpMethod = "POST"
    
    
    // let paramString = "access_token=\(keychain.get(OAuth2_Access_Token_Key)!)"
    //    request.httpBody = paramString.data(using: .utf8)
    // request.addValue("Token token=884288bae150b9f2f68d8dc3a932071d", forHTTPHeaderField: "Authorization")
    request.addValue("Bearer \(getAuth2AccessTokenString ()!)",
        forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request,
                                          completionHandler: { (data : Data?,
                                            response : URLResponse?, error : Error?) in
                                            if error == nil {
                                                let dataStr = String(data : data!, encoding : String.Encoding.utf8)
                                                print("dataString = \(dataStr)")
                                            }
                                            else {
                                                print("likeVid error = \(error!.localizedDescription)")
                                            }
    })
    
    task.resume()
    
}



/*
 get songs
 */



final class YouTube : NSObject
{
    private override init() {
        
    }
    
    static let shared = YouTube()
    
    // MARK:  Local ariables
    var playlists : [Playlist] = [] {
        didSet {
            NotificationCenter.default.post(name: FetchedNewPlaylistNotificationName, object: nil, userInfo: nil)
            populateItemsForPlaylists ()
        }
    }
    
    /* sets my global 'playlists' variabl*/
    func populatePlaylists ()
    {
        let getPlaylistsURLString = "https://www.googleapis.com/youtube/v3/playlists?part=snippet&mine=true"
        let getPlaylistURL = URL(string: getPlaylistsURLString)!
        var request = URLRequest(url: getPlaylistURL)
        request.httpMethod = "GET"
        
        if getAuth2AccessTokenString () == nil { return }
        
        request.addValue("Bearer \(getAuth2AccessTokenString ()!)",
            forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request,
                                              completionHandler: { (data : Data?,
                                                response : URLResponse?, error : Error?) in
                                                if error == nil {
                                                    let dataStr = String(data : data!, encoding : String.Encoding.utf8)
                                                    print("getplaylists: dataString = \(dataStr)")
                                                    
                                                    if let playlistsDictionary = try! JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                                                        print("playlists[items] = \(playlistsDictionary.object(forKey: "items"))")
                                                        let items = playlistsDictionary.object(forKey: "items") as! [NSDictionary]
                                                        self.playlists = Playlist.getPlaylists(fromDictionary: items)
                                                        
                                                    }
                                                }
                                                else {
                                                    print("likeVid error = \(error!.localizedDescription)")
                                                }
        })
        
        task.resume()
    }
    
    /* for each playlist, items are populated */
    func populateItemsForPlaylists () {
        for playlist in playlists {
            playlist.getItems()
        }
    }
}
