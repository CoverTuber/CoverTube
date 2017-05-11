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
// import YouTubePlayer
import YoutubeEngine
import CircularSpinner

class PlaylistViewController: UIViewController, YouTubePlayerDelegate, UIGestureRecognizerDelegate
{
    /* YouTube player view */
    @IBOutlet weak var youtubePlayerView : YouTubePlayerView!
    
    /* UIView on top of youtube player view to handle pan gesture recognizer since it doesn't handle any user interaction. This handles them instead. */
    @IBOutlet weak var youTubePlayerViewOverlayView: UIView!
    
    
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
    
    /* youtube player view's state. full, minimized, hidden */
    private var youtubePlayerViewSizeState = YouTubePlayerViewSizeState.fullScreen
    
    /*  */
    private var youtubePlayerViewCurrentCornerRadius : CGFloat = 0.0
    
    private var overlayViewCurrentCornerRadius : CGFloat = 0.0
    
    private var youtubePlayerViewCurrentTransformScale = maximizedYouTubePlayerViewTransformScale
    
    /* youtube player overlay view's pan gesture direction - up or down */
    private var youtubePlayerOverlayViewPanGestureDirection = YouTubePlayerViewOverlayDirection.down
    private var isUserPanningYoutubePlayerOverlayView = false
    
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
        
        youtubePlayerView.frame = rectangularFullYouTubePlayerViewFrame
        youTubePlayerViewOverlayView.frame = rectangularFullYouTubePlayerViewFrame
        youtubePlayerViewSizeState = YouTubePlayerViewSizeState.fullScreen
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        youtubePlayerView.frame = rectangularFullYouTubePlayerViewFrame
        youTubePlayerViewOverlayView.frame = rectangularFullYouTubePlayerViewFrame
        
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
        
        /* set up youtube player view's overlay view settings */
        youTubePlayerViewOverlayView.clipsToBounds = true
        youTubePlayerViewOverlayView.layer.cornerRadius = 0.0
        
        /* set up minimized youtube player view's overlay button.
         Make it into circle. */
        minimizedYouTubePlayerViewOverlayButton.clipsToBounds = true
        minimizedYouTubePlayerViewOverlayButton.layer.cornerRadius = minimizedYouTubePlayerCornerRadius
        minimizedYouTubePlayerViewOverlayButton.frame
            = CGRect(origin: minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint,
                     size: squareMinimizedYouTubePlayerSize)
        minimizedYouTubePlayerViewOverlayButton.setImage(UIImage.init(named: "play_icon_white_half.png") ,
                                                         for: UIControlState.normal)
        
        minimizedYouTubePlayerViewOverlayButton.tintColor = UIColor.white
        
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
        
        minimizedYouTubePlayerViewOverlayButton.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        
        view.bringSubview(toFront: youTubePlayerViewOverlayView)
        view.bringSubview(toFront: minimizeYouTubePlayerViewButton)
    }
    
    /* update UI with scale factor */
    func updateUI(withScale scaleFactor: CGFloat, toState : YouTubePlayerViewSizeState) {
        
        youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_CornerRadius)
        youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        
        let reverseScaleFactor = 1 - 0.5 * scaleFactor
        let scale = CGAffineTransform.init(scaleX: reverseScaleFactor, y: reverseScaleFactor)
        let scaledTransform = scale.concatenating(CGAffineTransform.init(translationX: -(youTubePlayerViewOverlayView.bounds.width / 4 * scaleFactor),
                                                                         y: -(youTubePlayerViewOverlayView.bounds.height / 4 * scaleFactor)))
        
        youTubePlayerViewOverlayView.transform = scaledTransform
        
        youtubePlayerView.layer.transform =  CATransform3DMakeAffineTransform(scaledTransform)
        youtubePlayerViewCurrentTransformScale = youtubePlayerView.layer.transform
        
        youTubePlayerViewOverlayView.layer.cornerRadius = scaleFactor * fullYouTubePlayerCornerRadius
        youtubePlayerView.layer.cornerRadius = scaleFactor * fullYouTubePlayerCornerRadius
        
        // TODO: Need to fix it still.
        youTubePlayerViewOverlayView.layer.bounds.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width)
        
        
        
        let s = (1 - 0.5 * scaleFactor)
        
        let x = (screenWidth / 2.0) - ( youTubePlayerViewOverlayView.layer.bounds.width) / 2.0 * s
        // + (screenWidth - fullYouTubePlayerViewOverlayView.layer.bounds.width) / 2.0 * s
        
        print("scaledWidth = \(youTubePlayerViewOverlayView.bounds.width * (1 ))")
        
        youTubePlayerViewOverlayView.frame.origin.x = x
        youTubePlayerViewOverlayView.frame.origin.y = screenHeight * scaleFactor
        
        
        CATransaction.begin()
        
        
        /* change position to bottom center */
        let movePositionToBottomCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToBottomCenterAnimation.toValue = youTubePlayerViewOverlayView.center
        movePositionToBottomCenterAnimation.duration = 0.00001
        movePositionToBottomCenterAnimation.isRemovedOnCompletion = false
        movePositionToBottomCenterAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(movePositionToBottomCenterAnimation, forKey: "movePositionToBottomCenterAnimationInUpdateUI")
        
        let squareBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        squareBoundsSizeWidthAnimation.toValue = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width)
        squareBoundsSizeWidthAnimation.duration = 0.00001
        squareBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        squareBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        youtubePlayerView.layer.add(squareBoundsSizeWidthAnimation, forKey: "squareBoundsSizeWidthAnimationInUpdateUI")
        CATransaction.commit()
        
        
        // youtubePlayerView.layer.frame.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width) // glitches!
        
        
        // youtubePlayerView.frame.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width) // glitches
        // youtubePlayerView.bounds.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width) // Glitches!
        
        // youtubePlayerView.layer.bounds.size.width = screenWidth - scaleFactor * ((screenWidth - squareFullYouTubePlayerSize.width)) // Glitches!
        
        print("fullYouTubePlayerViewOverlayView.layer.bounds.size = \(youTubePlayerViewOverlayView.layer.bounds.size)")
        
        
        print("\(scaleFactor) // \(reverseScaleFactor)")
        
        /* circularTimeProgressBar won't be visible till scaleFactor reaches 0.3 */
        circularTimeProgressBar.isHidden = false
        let scaledAlpha = 1.4 * scaleFactor - 0.4 // (1.0 / 0.7 * (scaleFactor - 1.0)) + 1.0
        print("scaledAlpha = \(scaledAlpha)")
        circularTimeProgressBar.alpha = scaleFactor < 0.3 ? 0.0 : scaledAlpha
        
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
            self.youtubePlayerViewSizeState = YouTubePlayerViewSizeState.minimized
            self.youtubePlayerViewCurrentCornerRadius = fullYouTubePlayerCornerRadius
            self.overlayViewCurrentCornerRadius = minimizedYouTubePlayerCornerRadius
            
            self.youtubePlayerViewCurrentTransformScale = minimizedYouTubePlayerViewTransformScale
            self.youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
            self.youtubePlayerView.layer.transform = minimizedYouTubePlayerViewTransformScale
            
            self.youtubePlayerView.layer.position = minimizedSizeBottomCenterYouTubePlayerCenterPoint
            self.youtubePlayerView.layer.cornerRadius = fullYouTubePlayerCornerRadius
            self.youTubePlayerViewOverlayView.layer.cornerRadius = minimizedYouTubePlayerCornerRadius
            // self.youtubePlayerView.layer.bounds.size.width = squareFullYouTubePlayerSize.width
            // self.youtubePlayerView.layer.bounds.size.height = squareFullYouTubePlayerSize.height
            
            self.youTubePlayerViewOverlayView.frame = minimizedSizeBottomCenterYouTubePlayerFrame
            print("overlayView.frame = \(self.youTubePlayerViewOverlayView.frame)")
            print("expected = \(minimizedSizeBottomCenterYouTubePlayerFrame)")
        }
        
        youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        
        /* transformScaleAnimation - shrink size animation */
        let transformScaleAnimation = CABasicAnimation(keyPath: "transform")
        transformScaleAnimation.fromValue = youtubePlayerViewCurrentTransformScale
        transformScaleAnimation.toValue = minimizedYouTubePlayerViewTransformScale
        transformScaleAnimation.duration = changeSizeAnimationDuration
        transformScaleAnimation.isRemovedOnCompletion = false
        transformScaleAnimation.fillMode = kCAFillModeForwards
        transformScaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(transformScaleAnimation, forKey: YouTubePlayerViewAnimation_TransformScale)
        
        /* change position to bottom center */
        let movePositionToBottomCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToBottomCenterAnimation.fromValue = youTubePlayerViewOverlayView.center // from wherever the current position is since the player view moves exactly the same as the overlay view.
        movePositionToBottomCenterAnimation.toValue = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        movePositionToBottomCenterAnimation.duration = changeSizeAnimationDuration
        movePositionToBottomCenterAnimation.isRemovedOnCompletion = false
        movePositionToBottomCenterAnimation.fillMode = kCAFillModeForwards
        movePositionToBottomCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(movePositionToBottomCenterAnimation, forKey: YouTubePlayerViewAnimation_Position)
        
        /* cornerRadius to make youtube player view shape into circular */
        let youtubePlayerViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        youtubePlayerViewCornerRadiusAnimation.fromValue = youtubePlayerViewCurrentCornerRadius
        youtubePlayerViewCornerRadiusAnimation.toValue = fullYouTubePlayerCornerRadius
        youtubePlayerViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // youtubePlayerViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // youtubePlayerViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        youtubePlayerViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(youtubePlayerViewCornerRadiusAnimation, forKey: YouTubePlayerViewAnimation_CornerRadius)
        
        /* cornerRadius to make overlay view shape into circular */
        let overlayViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        overlayViewCornerRadiusAnimation.toValue = minimizedYouTubePlayerCornerRadius
        overlayViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // overlayViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // overlayViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        overlayViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youTubePlayerViewOverlayView.layer.add(overlayViewCornerRadiusAnimation, forKey: MinimizeYouTubePlayerOverlayViewAnimation_CornerRadius)
        
        
        /* squraeBoundsAnimation - make size into square to make it into perfect circle.
         If I don't change the size to a square, then the shape will be changed into an oval. */
        let squareBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        squareBoundsSizeWidthAnimation.toValue = squareFullYouTubePlayerSize.width
        squareBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        squareBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        squareBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        squareBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(squareBoundsSizeWidthAnimation,
                                    forKey: YouTubePlayerViewAnimation_BoundsSizeWidth)
        
        /* squraeBoundsAnimation - make size into square to make it into perfect circle.
         If I don't change the size to a square, then the shape will be changed into an oval. */
        let squareBoundsSizeHeightAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        squareBoundsSizeHeightAnimation.toValue = squareFullYouTubePlayerSize.height
        squareBoundsSizeHeightAnimation.duration = changeSizeAnimationDuration
        squareBoundsSizeHeightAnimation.isRemovedOnCompletion = false
        squareBoundsSizeHeightAnimation.fillMode = kCAFillModeForwards
        squareBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(squareBoundsSizeHeightAnimation, forKey: YouTubePlayerViewAnimation_BoundsSizeHeight)
        
        /* keep youtube video at horizontal center */
        let keepYouTubeInHorizontalCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInHorizontalCenterAnimation.toValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInHorizontalCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInHorizontalCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInHorizontalCenterAnimation.fillMode = kCAFillModeForwards
        keepYouTubeInHorizontalCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(keepYouTubeInHorizontalCenterAnimation, forKey: YouTubePlayerViewAnimation_BoundsOriginX)
        
        /* keep youtube video at vertical center */
        let keepYouTubeInVerticalCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.y")
        keepYouTubeInVerticalCenterAnimation.toValue = 0.0
        keepYouTubeInVerticalCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInVerticalCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInVerticalCenterAnimation.fillMode = kCAFillModeForwards
        keepYouTubeInVerticalCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(keepYouTubeInVerticalCenterAnimation, forKey: YouTubePlayerViewAnimation_BoundsOriginY)
        
        isChangingYouTubePlayerViewSize = true
        
        CATransaction.commit()
        
        
        /* animate fullYouTubePlayerViewOverlayView */
        UIView.animate(withDuration: changeSizeAnimationDuration,
                       delay: 0.0,
                       options: UIViewAnimationOptions.curveEaseOut ,
                       animations: {
                        self.youTubePlayerViewOverlayView.frame = minimizedSizeBottomCenterYouTubePlayerFrame
                        self.circularTimeProgressBar.alpha = 1.0
        }) { (completed : Bool) in }
        
    }
    
    /* animate youtube player view from minimized circular shape at bottom to full rectuangular size at top */
    func maximizeYouTubePlayerViewAnimation()
    {
        /* if currently animating, return */
        if isChangingYouTubePlayerViewSize {
            return
        }
        
        /* remove previous animations */
        
        // minimizedYouTubePlayerViewOverlayButton.isHidden = true
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.isYouTubePlayerViewMinimized = false
            self.updateUI()
            self.isChangingYouTubePlayerViewSize = false
            self.youtubePlayerViewSizeState = YouTubePlayerViewSizeState.fullScreen
            self.youtubePlayerView.layer.cornerRadius = 0.0
            self.youtubePlayerViewCurrentCornerRadius = 0.0
            self.youTubePlayerViewOverlayView.layer.cornerRadius = 0.0
            self.overlayViewCurrentCornerRadius = 0.0
            self.youtubePlayerViewCurrentTransformScale = maximizedYouTubePlayerViewTransformScale
            self.youtubePlayerView.layer.transform = maximizedYouTubePlayerViewTransformScale
            self.stopYouTubePlayerViewSpinningAnimation()
        }
        
        youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_CornerRadius)
        
        /* transformScaleAnimation */
        // youtubePlayerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        
        let transformScaleAnimation = CABasicAnimation(keyPath: "transform")
        transformScaleAnimation.fromValue = youtubePlayerViewCurrentTransformScale
        // minimizedYouTubePlayerViewTransformScale
        
        transformScaleAnimation.toValue = maximizedYouTubePlayerViewTransformScale
        transformScaleAnimation.duration = changeSizeAnimationDuration
        // transformScaleAnimation.isRemovedOnCompletion = false
        // transformScaleAnimation.fillMode = kCAFillModeForwards
        transformScaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(transformScaleAnimation, forKey: MaximizeYouTubePlayerViewAnimation_TransformScale)
        
        /* change position to top center */
        let movePositionToTopCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToTopCenterAnimation.toValue = fullSizeTopYouTubePlayerCenterPoint
        movePositionToTopCenterAnimation.duration = changeSizeAnimationDuration
        movePositionToTopCenterAnimation.isRemovedOnCompletion = false
        movePositionToTopCenterAnimation.fillMode = kCAFillModeForwards
        movePositionToTopCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(movePositionToTopCenterAnimation, forKey: MaximizeYouTubePlayerViewAnimation_TopCenterPosition)
        
        /* cornerRadius for youtubePlayerView */
        let youtubePlayerViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        youtubePlayerViewCornerRadiusAnimation.fromValue = youtubePlayerViewCurrentCornerRadius
        youtubePlayerViewCornerRadiusAnimation.toValue = 0.0
        youtubePlayerViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // youtubePlayerViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // youtubePlayerViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        youtubePlayerViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(youtubePlayerViewCornerRadiusAnimation, forKey: "cornerRadius")
        
        /* cornerRadius for overlayView */
        let overlayViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        overlayViewCornerRadiusAnimation.fromValue = overlayViewCurrentCornerRadius
        overlayViewCornerRadiusAnimation.toValue = 0.0
        overlayViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // overlayViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // overlayViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        overlayViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youTubePlayerViewOverlayView.layer.add(overlayViewCornerRadiusAnimation, forKey: "cornerRadius")
        
        /* horizontal rectuangular boundsAnimation */
        let rectangularBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        rectangularBoundsSizeWidthAnimation.fromValue = squareFullYouTubePlayerSize.width
        rectangularBoundsSizeWidthAnimation.toValue = rectangularFullYouTubePlayerViewFrame.size.width
        rectangularBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        rectangularBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(rectangularBoundsSizeWidthAnimation,
                                    forKey: "squareBoundsSizeWidthAnimation")
        
        /* vertical rectuangular boundsAnimation */
        let rectangularBoundsSizeHeightAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        rectangularBoundsSizeHeightAnimation.fromValue = squareFullYouTubePlayerSize.height
        rectangularBoundsSizeHeightAnimation.toValue = rectangularFullYouTubePlayerViewFrame.height
        rectangularBoundsSizeHeightAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeHeightAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeHeightAnimation.fillMode = kCAFillModeForwards
        rectangularBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(rectangularBoundsSizeHeightAnimation,
                                    forKey: "squareBoundsSizeHeightAnimation")
        
        /* keep youtube video in center */
        let keepYouTubeInCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInCenterAnimation.fromValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInCenterAnimation.toValue = 0.0
        keepYouTubeInCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInCenterAnimation.fillMode = kCAFillModeForwards
        keepYouTubeInCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        youtubePlayerView.layer.add(keepYouTubeInCenterAnimation, forKey: "keepInCenter")
        
        CATransaction.commit()
        self.isChangingYouTubePlayerViewSize = true
        
        /* animate fullYouTubePlayerViewOverlayView and circularTimeProgressBar */
        
        UIView.animate(withDuration: changeSizeAnimationDuration, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.youTubePlayerViewOverlayView.frame = rectangularFullYouTubePlayerViewFrame
            self.circularTimeProgressBar.alpha = 0.0
        }) { (completed : Bool) in
            self.circularTimeProgressBar.isHidden = true
        }
        
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
    
    func stopYouTubePlayerViewSpinningAnimation () {
        youtubePlayerView.layer.removeAnimation(forKey: "spinningAnimation")
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
        
        /* animate circular time progress bar */
        circularTimeProgressBar.alpha = 0.0
        circularTimeProgressBar.isHidden = false
        
        UIView.animate(withDuration: changeSizeAnimationDuration * 0.5,
                       delay: changeSizeAnimationDuration * 0.5,
                       options: UIViewAnimationOptions.curveEaseOut,
                       animations: {
                        self.circularTimeProgressBar.alpha = 1.0
        }) { (completed : Bool) in }
        
        /* animate youtube player view */
        minimizeYouTubePlayerViewAnimation()
    }
    
    /* user taps this button to maximize youtube player view and stop spinning. */
    @IBAction func maximizeYouTubePlayerViewButtonTapped(_ sender: UIButton)
    {
        /* Animate circular progress bar to hide */
        circularTimeProgressBar.alpha = 1.0
        circularTimeProgressBar.isHidden = false
        UIView.animate(withDuration: changeSizeAnimationDuration * 0.5,
                       delay: changeSizeAnimationDuration * 0.5,
                       options: UIViewAnimationOptions.curveEaseOut,
                       animations: {
                        self.circularTimeProgressBar.alpha = 0.0
        }) { (completed : Bool) in self.circularTimeProgressBar.isHidden = true }
        
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
    
    
    func positionDuringSwipe(scaleFactor: CGFloat) -> CGPoint {
        let reverseScaleFactor = 1 - 0.5 * scaleFactor
        let playerViewWidth = screenWidth * reverseScaleFactor
        let x : CGFloat = ((screenWidth - playerViewWidth) / 2.0) + (screenWidth - squareFullYouTubePlayerSize.width) * 0.5 * scaleFactor
        
        // screenWidth / 2.0 - width / 2.0
        let y = screenHeight * scaleFactor // (screenHeight - 10) * scaleFactor - height
        let coordinate = CGPoint.init(x: x, y: y)
        return coordinate
    }
    
    
    // MARK: UIGestureRecognizer handling functions
    /*
     Reduce size of youtube player view as user pans the youtube player view to the bottom.
     */
    @IBAction func handleMinimizingGestureRecognizer(_ sender: UIPanGestureRecognizer)
    {
        if sender.state == .began {
            let velocity = sender.velocity(in: nil)
            print("velocity = \(velocity)")
            if velocity.y > 0
            {
                /* downwards swipe */
                youtubePlayerOverlayViewPanGestureDirection = YouTubePlayerViewOverlayDirection.down
            }
            else
            {
                /* upwards swipe */
                youtubePlayerOverlayViewPanGestureDirection = YouTubePlayerViewOverlayDirection.up
            }
            isUserPanningYoutubePlayerOverlayView = true
        }
        
        stopYouTubePlayerViewSpinningAnimation()
        
        var finalState = YouTubePlayerViewSizeState.fullScreen
        switch youtubePlayerViewSizeState
        {
        case .fullScreen:
            let factor = (sender.translation(in: nil).y / screenHeight) // (abs(sender.translation(in: nil).y) / UIScreen.main.bounds.height)
            updateUI(withScale: factor, toState: .minimized)
            // swipeToMinimize(translation: factor, toState: .minimized)
            finalState = .minimized
        case .minimized:
            finalState = .fullScreen
            let factor = 1 - (abs(sender.translation(in: nil).y) / UIScreen.main.bounds.height)
            // updateUI(withScale: factor)
            updateUI(withScale: factor, toState: .fullScreen)
        // swipeToMinimize(translation: factor, toState: .fullScreen)
        default: break
        }
        
        
        if sender.state == .ended
        {
            youtubePlayerViewSizeState = finalState
            
            /*
             animate()
             didEndedSwipe(toState: youtubePlayerViewSizeState)
             if youtubePlayerViewSizeState == .hidden {
             // self.videoPlayer.pause()
             }
             */
            isUserPanningYoutubePlayerOverlayView = false
            if youtubePlayerOverlayViewPanGestureDirection == YouTubePlayerViewOverlayDirection.down {
                minimizeYouTubePlayerViewAnimation()
            } else {
                maximizeYouTubePlayerViewAnimation()
            }
        }
        
    }
    
    /* Whenever a user likes a video, 
     overlay view like???
     
     */
    @IBAction func handleDoubleTapGestureRecognizerOnYouTubePlayerView(_ sender: UITapGestureRecognizer)
    {
        if  sender.view == youTubePlayerViewOverlayView
        {
            
        }
    }
    
    
    func didEndedSwipe(toState: YouTubePlayerViewSizeState){
        self.animatePlayView(toState: toState)
    }
    
    func animatePlayView(toState: YouTubePlayerViewSizeState) {
        switch toState {
        case .fullScreen:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
                // self.playVC.view.frame.origin = self.fullScreenOrigin
            })
        case .minimized:
            UIView.animate(withDuration: 0.3, animations: {
                // self.playVC.view.frame.origin = self.minimizedOrigin
            })
        case .hidden:
            UIView.animate(withDuration: 0.3, animations: {
                // self.playVC.view.frame.origin = self.hiddenOrigin
            })
        }
    }
    
    
    
}
