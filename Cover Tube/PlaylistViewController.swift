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
    /* radius of shrunk youtube player circular spinning button radius */
    let shrunkCircleRadius = screenWidth * 0.25
    
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
        animateYoutubeVideoPlayerToShrunkCircle()
    }
    
    /* animate youtube video player to shrunk circle */
    func animateYoutubeVideoPlayerToShrunkCircle()
    {
        /* animation duration */
        let animationDuration = 3.0
        
        
        /* reduce size */
        let shrinkBoundsSizeAnimation = CABasicAnimation(keyPath: "bounds.size")
        shrinkBoundsSizeAnimation.fromValue = youtubePlayerView.bounds.size
        shrinkBoundsSizeAnimation.toValue = CGSize(width: shrunkCircleRadius * 2,
                                                   height: shrunkCircleRadius * 2)
        shrinkBoundsSizeAnimation.duration = animationDuration
        shrinkBoundsSizeAnimation.fillMode = kCAFillModeForwards
        shrinkBoundsSizeAnimation.isRemovedOnCompletion = false
        shrinkBoundsSizeAnimation.delegate = self
        shrinkBoundsSizeAnimation.setValue("shrinkSize", forKey: "animationID")
        youtubePlayerView.layer.add(shrinkBoundsSizeAnimation, forKey: "bounds.size")
        
        
        /* change position to bottom center */
        let moveToBottomCenterAnimation = CABasicAnimation(keyPath: "position")
        moveToBottomCenterAnimation.fromValue = youtubePlayerView.center
        moveToBottomCenterAnimation.toValue = CGPoint(x: screenWidth / 2.0,
                                                      y: screenHeight - shrunkCircleRadius + 10.0)
        moveToBottomCenterAnimation.duration = animationDuration
        moveToBottomCenterAnimation.fillMode = kCAFillModeForwards
        moveToBottomCenterAnimation.isRemovedOnCompletion = false
        moveToBottomCenterAnimation.delegate = self
        moveToBottomCenterAnimation.setValue("moveToBottomCenter", forKey: "animationID")
        youtubePlayerView.layer.add(moveToBottomCenterAnimation, forKey: "position")
        
        
        /* corner radius animation */
        let shrinkToCircleAnimation = CABasicAnimation(keyPath: "cornerRadius")
        shrinkToCircleAnimation.fromValue = 0.0
        shrinkToCircleAnimation.toValue = shrunkCircleRadius
        shrinkToCircleAnimation.duration = animationDuration
        shrinkToCircleAnimation.fillMode = kCAFillModeForwards
        shrinkToCircleAnimation.isRemovedOnCompletion = false
        shrinkToCircleAnimation.delegate = self
        shrinkToCircleAnimation.setValue("shrinkToCircle", forKey: "animationID")
        
        youtubePlayerView.layer.add(shrinkToCircleAnimation, forKey: "cornerRadius")
        
        
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let animationID = anim.value(forKey: "animationID")
        {
            /*
            switch animationID as! String
            {
            case "moveToBottomCenter" :
                youtubePlayerView.center = CGPoint(x: screenWidth / 2.0, y: screenHeight - shrunkCircleRadius + 10.0)
            
            case "shrinkSize" :
                youtubePlayerView.bounds.size = CGSize(width: shrunkCircleRadius * 2, height: shrunkCircleRadius * 2)
                
            case "shrinkToCircle":
                youtubePlayerView.layer.cornerRadius = shrunkCircleRadius
                youtubePlayerView.bounds.size = CGSize(width: shrunkCircleRadius * 2, height: shrunkCircleRadius * 2)
                youtubePlayerView.center = CGPoint(x: screenWidth / 2.0, y: screenHeight - shrunkCircleRadius + 10.0)
                
            default:
                print("default")
            }
            */
        }
    }
    
}
