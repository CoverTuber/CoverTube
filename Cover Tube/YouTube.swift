//
//  YouTube.swift
//  Cover Tube
//
//  Created by June Suh on 5/14/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation

var youtubeToken = ""

let baseURLString = "https://www.googleapis.com/youtube/v3"
let likeURLString = "\(baseURLString)/videos/rate"

// "WsptdUFthWI"
func likeVideo (videoID : String)
{
    print("tok = \(keychain.get(OAuth2_Token_Key))")
    let likeURLString = "https://www.googleapis.com/youtube/v3/videos/rate?id=\(videoID)&rating=like"
    let likeURL = URL(string: likeURLString)!
    var request = URLRequest(url: likeURL)
    request.httpMethod = "POST"
    
    /* ???? */
    
    if keychain.get(OAuth2_Token_Key) == nil {
        print("OAuth2TokenKey is empty")
        return
    }
    
    
    let paramString = "access_token=\(keychain.get(OAuth2_Token_Key)!)"
    request.httpBody = paramString.data(using: .utf8)
    
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
