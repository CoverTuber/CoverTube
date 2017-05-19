//
//  Video.swift
//  Cover Tube
//
//  Created by June Suh on 5/18/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class Video: NSObject
{
    var etag = ""
    var id = ""
    var kind = YouTubeKinds.YouTube_Video
    var snippet : NSDictionary = [:]
    var channelID = ""
    var videoId = ""
    var thumbnailMediumURLString = ""
    var title = ""
    
    
    init(withDictionary dict : NSDictionary) {
        super.init()
        print("Video dict = \(dict)")
        etag = dict.object(forKey: "etag") as! String
        id = dict.object(forKey: "id") as! String
        snippet = dict.object(forKey: "snippet") as! NSDictionary
        let thumbnails = snippet.object(forKey: "thumbnails") as! NSDictionary
        let mediumThumbnail : NSDictionary = thumbnails.object(forKey: "medium") as! NSDictionary
        thumbnailMediumURLString = mediumThumbnail.object(forKey: "url") as! String
        
        title = snippet.object(forKey: "title") as! String
    }
    
    class func getVideos (fromDictionary videosDict : [NSDictionary]) -> [Video]
    {
        var result : [Video] = []
        
        /* iterate through each dictionary and make it into video */
        for videoDict in videosDict {
            let video = Video(withDictionary: videoDict)
            result.append(video)
        }
        
        return result
    }
    
    
}
