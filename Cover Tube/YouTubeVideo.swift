//
//  YouTubeVideo.swift
//  Cover Tube
//
//  Created by June Suh on 5/18/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class YouTubeVideo: NSObject
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
        
        let resourceId = snippet.object(forKey: "resourceId") as! NSDictionary
        videoId = resourceId.object(forKey: "videoId") as! String
    }
    
    class func getVideos (fromDictionary videosDict : [NSDictionary]) -> [YouTubeVideo]
    {
        var result : [YouTubeVideo] = []
        
        /* iterate through each dictionary and make it into video */
        for videoDict in videosDict {
            let video = YouTubeVideo(withDictionary: videoDict)
            result.append(video)
        }
        
        return result
    }
    
    
}
