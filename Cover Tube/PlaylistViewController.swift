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
import YoutubeEngine
import CircularSpinner

class PlaylistViewController: UIViewController, YouTubePlayerDelegate
{
    /* YouTube player view */
    @IBOutlet weak var youtubePlayerView: YouTubePlayerView!
    
    /* User taps this button to make YouTubePlayerView small */
    @IBOutlet weak var minimizeYouTubePlayerViewButton: UIButton!
    
    /* button that handles user interaction when youtube player view is minimized */
    @IBOutlet weak var minimizedYouTubePlayerViewOverlayButton: UIButton!
    
    /* circular progress bar when youtube player view is minimized. Shows how much time passed in video */
    var circularTimeProgressBar = CircularSpinner(frame: CGRect.zero)
    
    /* circularPro */
    private var updateCircularTimeProgressBarTimer : Timer? = nil
    
    /* Whether youtube player view is minimized or not */
    private var isYouTubePlayerViewMinimized = false
    
    /* whether currently in animation or not. Only visible when youtube player view visible */
    private var isChangingYouTubePlayerViewSize = false
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        youtubePlayerView.frame = rectangularFullYouTubePlayerViewSize
        
        if updateCircularTimeProgressBarTimer == nil {
            updateCircularTimeProgressBarTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateCircularTimeProgressBar) , userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        circularTimeProgressBar.removeFromSuperview()
        
        /* disable update circular time progress bar timer */
        if updateCircularTimeProgressBarTimer != nil {
            updateCircularTimeProgressBarTimer!.invalidate()
            updateCircularTimeProgressBarTimer = nil
        }
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
        
        /* set up play,pause button */
        
        /* set up circular progress bar */
        circularTimeProgressBar.type = .determinate
        circularTimeProgressBar.showDismissButton = false
        if circularTimeProgressBar.superview == nil {
            view.addSubview(circularTimeProgressBar)
        }
        circularTimeProgressBar.value = 0
        circularTimeProgressBar.frame.size = circularProgressBarFrameSize
        circularTimeProgressBar.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        circularTimeProgressBar.backgroundColor = UIColor.clear
        circularTimeProgressBar.titleLabel.isHidden = true
        circularTimeProgressBar.isUserInteractionEnabled = false
    }
    
    /*
     Updates UI components when states or settings change.
     Called whenever states, settings change.
     */
    func updateUI () {
        minimizedYouTubePlayerViewOverlayButton.isHidden = !isYouTubePlayerViewMinimized
        minimizeYouTubePlayerViewButton.isHidden = isYouTubePlayerViewMinimized
        
        circularTimeProgressBar.isHidden = !isYouTubePlayerViewMinimized
        
        circularTimeProgressBar.frame.size = circularProgressBarFrameSize
        circularTimeProgressBar.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        
        youtubePlayerView.frame = rectangularFullYouTubePlayerViewSize
    }
    
    func updateCircularTimeProgressBar () {
        circularTimeProgressBar.setValue(youtubePlayerView.getTimePercentage(), animated: true)
    }
    
    /* Animate full youtube player view to minimized circular shape to bottom */
    func minimizeYouTubePlayerViewAnimation ()
    {
        /* if currently animating, return */
        if isChangingYouTubePlayerViewSize {
            return
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.isYouTubePlayerViewMinimized = true
            self.updateUI()
            self.isChangingYouTubePlayerViewSize = false
            self.startYouTubePlayerViewSpinningAnimation()
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
        
        /* squraeBoundsAnimation - make size into square to make it into perfect circle.
         If I don't change the size to a square, then the shape will be changed into an oval. */
        let squareBoundsSizeHeightAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        squareBoundsSizeHeightAnimation.toValue = squareFullYouTubePlayerSize.height
        squareBoundsSizeHeightAnimation.duration = changeSizeAnimationDuration
        squareBoundsSizeHeightAnimation.isRemovedOnCompletion = false
        squareBoundsSizeHeightAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(squareBoundsSizeHeightAnimation, forKey: "squareBoundsSizeHeightAnimation")
        
        /* keep youtube video at horizontal center */
        let keepYouTubeInHorizontalCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInHorizontalCenterAnimation.toValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInHorizontalCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInHorizontalCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInHorizontalCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(keepYouTubeInHorizontalCenterAnimation, forKey: "keepInHorizontalCenter")
        
        /* keep youtube video at vertical center */
        let keepYouTubeInVerticalCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.y")
        keepYouTubeInVerticalCenterAnimation.toValue = 0.0
        keepYouTubeInVerticalCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInVerticalCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInVerticalCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(keepYouTubeInVerticalCenterAnimation, forKey: "keepInVerticalCenter")
        
        isChangingYouTubePlayerViewSize = true
        
        CATransaction.commit()

    }
    
    /* animate youtube player view from minimized circular shape at bottom to full rectuangular size at top */
    func maximizeYouTubePlayerViewAnimation()
    {
        /* if currently animating, return */
        if isChangingYouTubePlayerViewSize {
            return
        }
        
        // hide upper right button tapped to minimize youtube player view
        minimizedYouTubePlayerViewOverlayButton.isHidden = true
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.isYouTubePlayerViewMinimized = false
            self.updateUI()
            self.isChangingYouTubePlayerViewSize = false
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
        
        /* horizontal rectuangular boundsAnimation */
        let rectangularBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        rectangularBoundsSizeWidthAnimation.fromValue = squareFullYouTubePlayerSize.width
        rectangularBoundsSizeWidthAnimation.toValue = rectangularFullYouTubePlayerViewSize.width
        rectangularBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(rectangularBoundsSizeWidthAnimation,
                                    forKey: "squareBoundsSizeWidthAnimation")
        
        /* vertical rectuangular boundsAnimation */
        let rectangularBoundsSizeHeightAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        rectangularBoundsSizeHeightAnimation.fromValue = squareFullYouTubePlayerSize.height
        rectangularBoundsSizeHeightAnimation.toValue = rectangularFullYouTubePlayerViewSize.height
        rectangularBoundsSizeHeightAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeHeightAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeHeightAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(rectangularBoundsSizeHeightAnimation,
                                    forKey: "squareBoundsSizeHeightAnimation")
        
        /* keep youtube video in center */
        let keepYouTubeInCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInCenterAnimation.fromValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInCenterAnimation.toValue = 0.0
        keepYouTubeInCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(keepYouTubeInCenterAnimation, forKey: "keepInCenter")
        
        CATransaction.commit()
        self.isChangingYouTubePlayerViewSize = true
    }
    
    /* spins youtube player view is currently playing. */
    func startYouTubePlayerViewSpinningAnimation() {
        /* if youtube video is not playing, don't spin */
        if youtubePlayerView.playerState != YouTubePlayerState.Playing {
            return
        }
        
        let spinningAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        spinningAnimation.toValue = Double.pi * 2
        spinningAnimation.repeatCount = .infinity
        spinningAnimation.duration = (CFTimeInterval(Float(1.0) / minimizedYouTubePlayerViewRotationSpeed)) * 0.75
        spinningAnimation.speed = minimizedYouTubePlayerViewRotationSpeed
        spinningAnimation.isCumulative = true
        youtubePlayerView.layer.add(spinningAnimation, forKey: "spinningAnimation")
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
        // youtubePlayerView.loadVideoID("PT2_F-1esPk") // chainsmokers closer original video
        youtubePlayerView.loadVideoID("WsptdUFthWI")
        // chainsmokers closer cover video - WsptdUFthWI
        // test rectangle - wM0HvuP5Aps
    }
    
    // MARK: YouTubePlayer delegate
    func playerReady(_ videoPlayer: YouTubePlayerView) {
        if videoPlayer == youtubePlayerView && !didAutoplayPreviously {
            self.playYouTubePlayerView()
        }
    }
    
    /*
     NOTE: UIAlertView - you can play the music by swiping up.
                       - when the music stops, this delegate method is being called
     */
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        if videoPlayer.playerState == YouTubePlayerState.Playing && isYouTubePlayerViewMinimized {
            self.startYouTubePlayerViewSpinningAnimation()
        } else if videoPlayer.playerState == YouTubePlayerState.Paused {
            
        }
    }
    
    /* user taps this button to minimize youtube player view */
    @IBAction func minimizeYouTubePlayerViewButtonTapped(_ sender: UIButton)
    {
        sender.isHidden = true
        
        circularTimeProgressBar.alpha = 0.0
        circularTimeProgressBar.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.circularTimeProgressBar.alpha = 1.0
        }
        
        minimizeYouTubePlayerViewAnimation()
    }
    
    /* user taps this button to maximize youtube player view and stop spinning. */
    @IBAction func maximizeYouTubePlayerViewButtonTapped(_ sender: UIButton)
    {
        
        circularTimeProgressBar.alpha = 1.0
        circularTimeProgressBar.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.circularTimeProgressBar.alpha = 0.0
        }
        
        maximizeYouTubePlayerViewAnimation()
        
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

    override var prefersStatusBarHidden : Bool {
        return true
    }

}
