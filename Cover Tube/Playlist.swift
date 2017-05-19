//
//  Playlist.swift
//  Cover Tube
//
//  Created by June Suh on 5/17/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

enum YouTubeKinds {
    case YouTube_Playlist
    case YouTube_Playlist_Item
    case YouTube_Video
}
let kinds = ["youtube#playlist" : YouTubeKinds.YouTube_Playlist,
             "youtube#playlistItemListResponse" : YouTubeKinds.YouTube_Playlist_Item,
             "youtube#video" : YouTubeKinds.YouTube_Video]

class Playlist: NSObject {
    var etag = ""
    var id = ""
    var kind = YouTubeKinds.YouTube_Playlist
    var snippet : NSDictionary = [:]
    var title = ""
    var descriptionStr = ""
    var publishedAtDateStr = ""
    var publishedAtDate = Date(timeIntervalSince1970: 0.0)
    
    var thumbnails : NSDictionary = [:]
    var thumbnailMediumURLString = ""
    
    var videos : [Video] = []
    
    init(withDictionary dict : NSDictionary) {
        super.init()
        print("playlist dictionary = \(dict)")
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.zzzZ"
        print("publishedAtDateStr - \(publishedAtDateStr)")
        if let date = dateFormatter.date(from: publishedAtDateStr) {
            publishedAtDate = date
        }
            
        print("title = \(title) etag = \(etag), id = \(id), kind \(kind), medURL = \(thumbnailMediumURLString)")
    }
    
    /*
     Given dictionary of playlistDictionary, 
     return it as an array of Playlist sorted by date
     */
    class func getPlaylists(fromDictionary playlistDictionaries : [NSDictionary]) -> [Playlist]
    {
        var result : [Playlist] = []
        
        /* iterate through each playlist dictionary and make it into a Playlist object */
        for playlistDict in playlistDictionaries
        {
            let newPlaylist = Playlist(withDictionary: playlistDict)
            result.append(newPlaylist)
        }
        
        result = result.sorted(by: { (playlist1 : Playlist, playlist2 : Playlist) -> Bool in
            playlist1.publishedAtDate > playlist2.publishedAtDate
        })
        
        return result
    }
    
    /* fetch  */
    func getItems () {
        if id.isEmpty {
            return
        }
        
        let getPlaylistItemsURLString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=\(id)"
        let getPlaylistItemsURL = URL(string: getPlaylistItemsURLString)!
        var request = URLRequest(url: getPlaylistItemsURL)
        request.httpMethod = "GET"
        
        if getAuth2AccessTokenString() == nil { return }
        
        
        request.addValue("Bearer \(getAuth2AccessTokenString ()!)",
            forHTTPHeaderField: "Authorization")
    
        let task = URLSession.shared.dataTask(with: request,
                                              completionHandler: { (data : Data?,
                                                response : URLResponse?, error : Error?) in
                                                if error == nil {
                                                    let dataStr = String(data : data!, encoding : String.Encoding.utf8)
                                                    print("getplaylistItems: dataString = \(dataStr)")
                                                    if let playlistItemsDictionary = try! JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary
                                                    {
                                                        let playlistItems = playlistItemsDictionary.object(forKey: "items") as! [NSDictionary]
                                                        self.videos = Video.getVideos(fromDictionary: playlistItems)
                                                    }
                                                }
                                                else {
                                                    print("getPlaylistItems error = \(error!.localizedDescription)")
                                                }
        })
        
        task.resume()
        
    }

}
