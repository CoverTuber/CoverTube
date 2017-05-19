//
//  PlaylistViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/4/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

//  NOTE: The youtube player view does not handle user interaction direction.
//        They are handled by its delegate methods and other ui components.

import UIKit
import AFNetworking

class PlaylistViewController: UIViewController,
    UICollectionViewDelegate, UICollectionViewDataSource
{
    // MARK: UI Element properties
    @IBOutlet weak var playlistCollectionView: UICollectionView!
    
    // MARK: ViewController life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fetchedNewPlaylists),
                                               name: FetchedNewPlaylistNotificationName,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UICollectionView Datasource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return YouTube.shared.playlists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath) as! PlaylistCollectionViewCell
        
        let playlist = YouTube.shared.playlists[indexPath.item]
        
        cell.titleLabel.text = playlist.title
        if let imageURL = URL(string: playlist.thumbnailMediumURLString) {
            cell.thumbnail.setImageWith(imageURL)
        }
        
        return cell
    }
    
    
    /* user tapped  */
    @IBAction func playlistTapped(_ sender: UIButton)
    {
        let tappedPoint = playlistCollectionView.convert(sender.center, from: sender.superview)
        if let tappedIndexPath = playlistCollectionView.indexPathForItem(at: tappedPoint)
        {
            print("tappedIndexPath = \(tappedIndexPath)")
            let selectedPlaylist = YouTube.shared.playlists[tappedIndexPath.item]
            
            var userInfo : [String : Any] = [:]
            userInfo["selectedPlaylist"] = selectedPlaylist
            userInfo["shuffledPlay"] = false
            
            NotificationCenter.default.post(name: TappedPlaylistNotificationName,
                                            object: nil, userInfo: userInfo)
        }
    }
    
    @IBAction func shufflePlayButtonTapped(_ sender: UIButton)
    {
        
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    /* hide status bar */
    override var prefersStatusBarHidden : Bool {
        return true
    }

    func fetchedNewPlaylists () {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.playlistCollectionView.reloadData()
        }
    }
    
    
}
