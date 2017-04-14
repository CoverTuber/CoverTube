//
//  PlaylistViewController.swift
//  Cover Tube
//
//  Created by June Suh on 4/10/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CAAnimationDelegate
{
    
    @IBOutlet weak var playlistTableView: UITableView!
    
    @IBOutlet weak var youtubePlayerView: YTPlayerView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        youtubePlayerView.load(withVideoId: "M7lc1UVf-VE")
        
        youtubePlayerView.clipsToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.cellForRow(at: indexPath) as! MusicTableViewCell
        /* make thumbnailImageView circular */
        cell.thumbnamilImageView.layer.cornerRadius = cell.thumbnamilImageView.frame.size.width / 2.0
        cell.thumbnamilImageView.clipsToBounds = true
        /*
         cell.thumbnamilImageView.image =
         */
        
        return cell
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    @IBAction func blueButtonTapped(_ sender: UIButton)
    {
        animateYoutubeVideoPlayerToCircle()
    }
    
    func animateYoutubeVideoPlayerToCircle()
    {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = 0.0
        animation.toValue = youtubePlayerView.frame.size.width / 2.0
        animation.duration = 3.0
        animation.delegate = self
        animation.setValue("circle", forKey: "animationID")
        
        youtubePlayerView.layer.add(animation, forKey: "cornerRadius")
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        print("anim = \(anim)")
        if let animationID = anim.value(forKey: "animationID")
        {
            if animationID as! String == "circle"
            {
                print("youtubePlayerView.frame.size.width = \(youtubePlayerView.frame.size.width / 2.0)")
                youtubePlayerView.layer.cornerRadius = youtubePlayerView.frame.size.width / 2.0
            }
            
            print("animationId = \(animationID)")
            
        }
    }
    
}
