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
import YouTubePlayer

class PlaylistViewController: UIViewController, YouTubePlayerDelegate
{
    /* YouTube player view */
    @IBOutlet weak var youtubePlayerView: YouTubePlayerView!
    
    /* User taps this button to make YouTubePlayerView small */
    @IBOutlet weak var minimizeYouTubePlayerViewButton: UIButton!
    
    
    /* button that handles user interaction when youtube player view is minimized */
    @IBOutlet weak var minimizedYouTubePlayerViewOverlayButton: UIButton!
    
    /* Whether youtube player view is minimized or not */
    private var isYouTubePlayerViewIsMinimized = false
    
    /* Whether autoplay has been played or not previously or not.
     This variable is used to prevent autoplaying all the time. */
    private var didAutoplayPreviously = false

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        didAutoplayPreviously = false
        
        updateUI()
        
        /*  load video */
        loadVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UI function
    
    /*
     sets up the settings for UI elements for settings that only need to be set once.
     Called in viewDidLoad function.
     */
    func setupUI () {
        /* set up youtube player view's settings */
        youtubePlayerView.isUserInteractionEnabled = false
        youtubePlayerView.delegate = self
        youtubePlayerView.clipsToBounds = true
        youtubePlayerView.layer.cornerRadius = 0.0
        
        /* set up minimized youtube player view's overlay button.
           Make it into circle. */
        minimizedYouTubePlayerViewOverlayButton.clipsToBounds = true
        minimizedYouTubePlayerViewOverlayButton.layer.cornerRadius = minimizedYouTubePlayerCornerRadius
        minimizedYouTubePlayerViewOverlayButton.frame
            = CGRect(origin: minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint,
                     size: squareMinimizedYouTubePlayerSize)
        
    }
    
    /*
     Updates UI components when states or settings change.
     Called whenever states, settings change.
     */
    func updateUI () {
        minimizedYouTubePlayerViewOverlayButton.isHidden = !isYouTubePlayerViewIsMinimized
        
    }
    
    /* Animate full youtube player view to minimized circular shape to bottom */
    func minimizeYouTubePlayerViewAnimation () {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.isYouTubePlayerViewIsMinimized = true
            self.updateUI()
            // self.startSpinningPlayerView()
        }
        
        /* transformScaleAnimation - shrink size animation */
        let transformScaleAnimation = CABasicAnimation(keyPath: "transform")
        transformScaleAnimation.toValue = CATransform3DScale(CATransform3DIdentity, 0.5, 0.5, 1.0)
        transformScaleAnimation.duration = changeSizeAnimationDuration
        transformScaleAnimation.isRemovedOnCompletion = false
        transformScaleAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(transformScaleAnimation, forKey: "transformScaleAnimation1")
        
        /* change position to bottom center */
        let movePositionToBottomCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToBottomCenterAnimation.toValue = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        movePositionToBottomCenterAnimation.duration = changeSizeAnimationDuration
        movePositionToBottomCenterAnimation.isRemovedOnCompletion = false
        movePositionToBottomCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(movePositionToBottomCenterAnimation, forKey: "movePositionToBottomCenterAnimation")
        
        /* cornerRadius to make shape into circular */
        let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        cornerRadiusAnimation.toValue = fullYouTubePlayerCornerRadius
        cornerRadiusAnimation.duration = changeSizeAnimationDuration
        cornerRadiusAnimation.isRemovedOnCompletion = false
        cornerRadiusAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(cornerRadiusAnimation, forKey: "cornerRadius")
        
        /* squraeBoundsAnimation - make size into square to make it into perfect circle.
         If I don't change the size to a square, then the shape will be changed into an oval. */
        let squareBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        squareBoundsSizeWidthAnimation.toValue = squareFullYouTubePlayerSize.width
        squareBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        squareBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        squareBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(squareBoundsSizeWidthAnimation, forKey: "squareBoundsSizeWidthAnimation")
        
        /* keep youtube video in center */
        let keepYouTubeInCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInCenterAnimation.toValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(keepYouTubeInCenterAnimation, forKey: "keepInCenter")
        
        CATransaction.commit()

    }
    
    /* animate youtube player view from minimized circular shape at bottom to full rectuangular size at top */
    func maximizeAnimation() {
        minimizedYouTubePlayerViewOverlayButton.isHidden = true
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.isYouTubePlayerViewIsMinimized = false
            self.updateUI()
        }
        
        /* transformScaleAnimation */
        let transformScaleAnimation = CABasicAnimation(keyPath: "transform")
        transformScaleAnimation.fromValue = CATransform3DScale(CATransform3DIdentity, 0.5, 0.5, 1.0)
        transformScaleAnimation.toValue = CATransform3DScale(CATransform3DIdentity, 1.0, 1.0, 1.0)
        transformScaleAnimation.duration = changeSizeAnimationDuration
        transformScaleAnimation.isRemovedOnCompletion = false
        transformScaleAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(transformScaleAnimation, forKey: "transformScaleAnimation2")
        
        /* change position to top center */
        let movePositionToTopCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToTopCenterAnimation.toValue = fullSizeTopYouTubePlayerCenterPoint
        movePositionToTopCenterAnimation.duration = changeSizeAnimationDuration
        movePositionToTopCenterAnimation.isRemovedOnCompletion = false
        movePositionToTopCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(movePositionToTopCenterAnimation, forKey: "movePositionToTopCenterAnimation")
        
        /* cornerRadius */
        let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        cornerRadiusAnimation.fromValue = fullYouTubePlayerCornerRadius
        cornerRadiusAnimation.toValue = 0.0
        cornerRadiusAnimation.duration = changeSizeAnimationDuration
        cornerRadiusAnimation.isRemovedOnCompletion = false
        cornerRadiusAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(cornerRadiusAnimation, forKey: "cornerRadius")
        
        /* squraeBoundsAnimation */
        let rectangularBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        rectangularBoundsSizeWidthAnimation.fromValue = squareFullYouTubePlayerSize.width
        rectangularBoundsSizeWidthAnimation.toValue = rectangularFullYouTubePlayerViewSize.width
        rectangularBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(rectangularBoundsSizeWidthAnimation,
                                    forKey: "squareBoundsSizeWidthAnimation")
        
        /* keep youtube video in center */
        let keepYouTubeInCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInCenterAnimation.fromValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInCenterAnimation.toValue = 0.0
        keepYouTubeInCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(keepYouTubeInCenterAnimation, forKey: "keepInCenter")
        
        CATransaction.commit()
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    /* 
     function loadVideo sets up the YouTubePlayer view's parameters and gives the youtube video's id
     */
    func loadVideo()
    {
        /* youtube player's variables */
        youtubePlayerView.playerVars = [
            "playsinline": "1" as AnyObject,
            "controls": "0" as AnyObject,
            "showinfo": "0" as AnyObject,
            "modestbranding" : "0" as AnyObject,
            "disablekb" : "1" as AnyObject,
            "rel" : "0" as AnyObject
        ]
        
        /* load video with youtube video's id. */
        youtubePlayerView.loadVideoID("XKu_SEDAykw") // google vid
    }
    
    // MARK: YouTubePlayer delegate
    func playerReady(_ videoPlayer: YouTubePlayerView) {
        if videoPlayer == youtubePlayerView && !didAutoplayPreviously {
            self.playYouTubePlayerView()
        }
    }
    
    /* user taps this button to minimize youtube player view */
    @IBAction func minimizeYouTubePlayerViewButtonTapped(_ sender: UIButton)
    {
        sender.isHidden = true
        minimizeYouTubePlayerViewAnimation()
    }
    
    /* user taps this button to maximize youtube player view and stop spinning. */
    @IBAction func maximizeYouTubePlayerViewButtonTapped(_ sender: UIButton)
    {
        maximizeAnimation()
    }
    
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        playYouTubePlayerView()
    }
    
    /*
     If the youtube player view is ready, play it.
     Else, pause it.
     */
    func playYouTubePlayerView ()
    {
        if youtubePlayerView.ready {
            if youtubePlayerView.playerState != YouTubePlayerState.Playing {
                youtubePlayerView.play()
            } else {
                youtubePlayerView.pause()
            }
        }
    }


}
