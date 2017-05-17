//
//  Playlist.swift
//  Cover Tube
//
//  Created by June Suh on 5/17/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

var playlists : [Playlist] = []

enum YouTubeKinds {
    case YouTube_Playlist
}
let kinds = ["youtube#playlist" : YouTubeKinds.YouTube_Playlist]

class Playlist: NSObject {
    var etag = ""
    var id = ""
    var kind = YouTubeKinds.YouTube_Playlist
    var snippet : NSDictionary = [:]
    var title = ""
    var descriptionStr = ""
    var publishedAtDateStr = ""
    var thumbnails : NSDictionary = [:]
    var thumbnailMediumURLString = ""
    
    init(withDictionary dict : NSDictionary) {
        super.init()
        etag = dict.object(forKey: "etag") as! String
        id = dict.object(forKey: "id") as! String
        kind = kinds[dict.object(forKey: "kind") as! String]!
        snippet = dict.object(forKey: "snippet") as! NSDictionary
        title = snippet.object(forKey: "title") as! String
        descriptionStr = snippet.object(forKey: "description") as! String
        publishedAtDateStr = snippet.object(forKey: "publishedAt") as! String
        
        thumbnails = snippet.object(forKey: "thumbnails") as! NSDictionary
        
        let mediumThumbnail : NSDictionary = thumbnails.object(forKey: "medium") as! NSDictionary
        thumbnailMediumURLString = mediumThumbnail.object(forKey: "url") as! String
            
        print("title = \(title) etag = \(etag), id = \(id), kind \(kind), medURL = \(thumbnailMediumURLString)")
    }
    
    /*
     Given dictionary of playlistDictionary, 
     return it as an array of Playlist
     */
    class func getPlaylists(fromDictionary playlistDictionaries : [NSDictionary]) -> [Playlist]
    {
        var result : [Playlist] = []
        for playlistdict in playlistDictionaries
        {
            let newPlaylist = Playlist(withDictionary: playlistdict)
            result.append(newPlaylist)
        }
        return result
    }

}
