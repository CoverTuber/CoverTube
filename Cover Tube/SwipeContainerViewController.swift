//
//  SwipeContainerViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/4/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//
//  The YouTube Video player is on top of all view controllers
//  NOTE: The youtube player view does not handle user interaction direction.
//        They are handled by its delegate methods and other ui components.

import UIKit
import YoutubeEngine
import CircularSpinner
import UXMVolumeOverlay
import SnapchatSwipeContainer
import flareview

class SwipeContainerViewController : SnapchatSwipeContainerViewController,
    YouTubePlayerDelegate, UIGestureRecognizerDelegate,
    UITableViewDelegate, UITableViewDataSource
{
    // MARK: UI Element properties
    /* YouTube player view */
    @IBOutlet weak var playerView : YouTubePlayerView!
    
    /* Player view's overlay view to display buttons, info on top of player view */
    @IBOutlet weak var playerOverlayView: UIView!
    
    @IBOutlet weak var repeatButton: RepeatButton!
    
    @IBOutlet weak var shuffleButton: UIButton!
    
    /* image used to animate like, play, pause, next, previous on top of player view */
    @IBOutlet weak var overlayImageView: UIImageView!
    
    /* displays current time of video */
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    /* displays duration of video */
    @IBOutlet weak var durationLabel: UILabel!
    
    /* UIView on top of youtube player view to handle pan gesture recognizer since it doesn't handle any user interaction. This handles them instead. */
    @IBOutlet weak var playerViewGestureHandlerView: UIView!
    
    /* User taps this button to make PlayerView small */
    @IBOutlet weak var minimizePlayerViewButton: UIButton!
    
    /* button that handles user interaction when youtube player view is minimized */
    @IBOutlet weak var minimizedPlayerViewOverlayButton: UIButton!
    
    /* button for previous song */
    @IBOutlet weak var prevButton: UIButton!
    
    /* button for next song */
    @IBOutlet weak var nextButton: UIButton!
    
    /* displays songs in current playlist */
    @IBOutlet weak var currentPlaylistTableview: UITableView!
    
    /* linear time progress bar. Below rectangular youtube player view that's customized */
    let linearTimeProgressBar = UISlider(frame: linearTimeProgressBarFrame)
    
    /* circular progress bar when youtube player view is minimized. Shows how much time passed in video */
    let circularTimeProgressBar = CircularSpinner(frame: CGRect.zero)
    
    // MARK: gesture recognizers
    @IBOutlet var overlayViewSingleTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var overlayViewDoubleTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var overlayViewPanGestureRecognizer: UIPanGestureRecognizer!
    
    // MARK: timer
    private var updateVideoTimeInfoTimer : Timer? = nil
    
    /* Whether youtube player view is minimized or not */
    private var isPlayerViewMinimized = false
    
    /* whether currently in animation or not. Only visible when youtube player view visible */
    private var isChangingYouTubePlayerViewSize = false
    
    /* Whether autoplay has been played or not previously or not.
     This variable is used to prevent autoplaying all the time. */
    private var didAutoplayPreviously = false
    
    /* youtube player view's state. full, minimized, hidden */
    private var playerViewSizeState = YouTubePlayerViewSizeState.fullScreen
    
    /* playerView's current corner radius */
    private var playerViewCurrentCornerRadius : CGFloat = 0.0
    
    /* overlay view's current corner radius */
    private var overlayViewCurrentCornerRadius : CGFloat = 0.0
    
    /* playerView's current transform scale */
    private var playerViewCurrentTransformScale = maximizedYouTubePlayerViewTransformScale
    
    /* youtube player overlay view's pan gesture direction - up or down */
    private var youtubePlayerOverlayViewPanGestureDirection = YouTubePlayerViewOverlayDirection.down
    
    /* whether user is panning video player or not */
    private var isUserPanningPlayerOverlayView = false
    
    // MARK: ViewController life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupUI()
        
        overlayViewSingleTapGestureRecognizer.require(toFail: overlayViewDoubleTapGestureRecognizer)
        overlayViewSingleTapGestureRecognizer.require(toFail: overlayViewPanGestureRecognizer)
        // overlayViewSingleTapGestureRecognizer.requiresExclusiveTouchType = true
        // overlayViewSingleTapGestureRecognizer.cancelsTouchesInView = false
        overlayViewPanGestureRecognizer.cancelsTouchesInView = true
        
        overlayViewPanGestureRecognizer.require(toFail: overlayViewSingleTapGestureRecognizer)
        overlayViewSingleTapGestureRecognizer.delegate = self
        overlayViewPanGestureRecognizer.delegate = self
        
        if storyboard != nil {
            let musicDetectionViewController = storyboard!.instantiateViewController(withIdentifier: "MusicDetectionVC")
            
            let playlistViewController = storyboard!.instantiateViewController(withIdentifier: "PlaylistVC")
            
            let bilboardViewController = storyboard!.instantiateViewController(withIdentifier: "BilboardVC")
            
            let viewControllers = [musicDetectionViewController, playlistViewController, bilboardViewController]
            setupScrollView(viewControllers: viewControllers)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        didAutoplayPreviously = false
        
        updateUI()
        
        /*  load video */
        loadVideo()
        
        playerView.frame = rectangularFullYouTubePlayerViewFrame
        playerOverlayView.frame = rectangularFullYouTubePlayerOverlayViewFrame
        playerViewGestureHandlerView.frame = rectangularFullYouTubePlayerOverlayViewFrame
        playerViewSizeState = YouTubePlayerViewSizeState.fullScreen
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerView.frame = rectangularFullYouTubePlayerViewFrame
        playerOverlayView.frame = rectangularFullYouTubePlayerOverlayViewFrame
        playerViewGestureHandlerView.frame = rectangularFullYouTubePlayerOverlayViewFrame
        
        /* if updateVideoTimeInfoTimer isn't set, initialize it. */
        if updateVideoTimeInfoTimer == nil {
            updateVideoTimeInfoTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                            target: self,
                                                            selector: #selector(updateVideoTimeInfo) ,
                                                            userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        circularTimeProgressBar.removeFromSuperview()
        
        /* disable update video time info timer */
        if updateVideoTimeInfoTimer != nil {
            updateVideoTimeInfoTimer!.invalidate()
            updateVideoTimeInfoTimer = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: SwipeContainerViewController functions
    
    // MARK: UI function
    
    /*
     sets up the settings for UI elements for settings that only need to be set once.
     Called in viewDidLoad function.
     */
    func setupUI () {
        /* set up youtube player view's settings */
        playerView.isUserInteractionEnabled = false
        playerView.delegate = self
        playerView.clipsToBounds = true
        playerView.layer.cornerRadius = 0.0
        
        /* set up repeat button */
        repeatButton.center = CGPoint(x: screenWidth / 2.0,
                                      y: 8.0 + repeatButton.frame.size.height / 2.0)
        
        /* set up shuffle button */
        shuffleButton.center = CGPoint(x: screenWidth * 0.75, y: 8.0 + shuffleButton.frame.size.height / 2.0)
        
        
        /* set up youtube player's view that handles gestures settings */
        playerViewGestureHandlerView.clipsToBounds = true
        playerViewGestureHandlerView.layer.cornerRadius = 0.0
        
        /* set up minimized youtube player view's overlay button.
         Make it into circle. */
        minimizedPlayerViewOverlayButton.clipsToBounds = true
        minimizedPlayerViewOverlayButton.layer.cornerRadius = minimizedYouTubePlayerCornerRadius
        minimizedPlayerViewOverlayButton.frame
            = CGRect(origin: minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint,
                     size: squareMinimizedYouTubePlayerSize)
        minimizedPlayerViewOverlayButton.setImage(UIImage.init(named: "play_icon_white_half.png") ,
                                                  for: UIControlState.normal)
        
        minimizedPlayerViewOverlayButton.tintColor = UIColor.white
        
        /* set up play,pause button */
        
        /* set up previous button */
        prevButton.clipsToBounds = true
        prevButton.layer.cornerRadius = previousButtonCornerRadius
        prevButton.center = previousButtonCenter
        
        /* set up next button */
        nextButton.clipsToBounds = true
        nextButton.layer.cornerRadius = nextButtonCornerRadius
        nextButton.center = nextButtonCenter
        
        /* set up linear time progress bar */
        // linearTimeProgressBar.currentThumbImage =
        linearTimeProgressBar.minimumTrackTintColor = minimumTrackColor
        linearTimeProgressBar.maximumTrackTintColor = maximumTrackColor
        linearTimeProgressBar.addTarget(self,
                                        action: #selector(linearTimeProgressBarValueChangec(_:)),
                                        for: .valueChanged)
        view.addSubview(linearTimeProgressBar)
        linearTimeProgressBar.center = CGPoint(x: screenWidth / 2.0, y: playerView.frame.size.height)
        
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
        
        currentTimeLabel.frame = CGRect(x: 10.0, y: playerOverlayView.frame.size.height - 21.0 - 30.0,
                                        width: 42, height: 21)
        durationLabel.frame = CGRect(x: screenWidth - 10.0 - 42.0, y: playerOverlayView.frame.size.height - 21.0 - 30.0, width: 42.0, height: 21.0)
        
        
        /* set up volume UI at top of screen */
        UXMVolumeOverlay.shared.load()
        UXMVolumeOverlay.shared.backgroundColor = UIColor.clear
        (UXMVolumeOverlay.shared.progressIndicator as! UXMVolumeProgressView).trackColor = minimumTrackColor
        
        /* setup currentPlaylistTableView */
        currentPlaylistTableview.frame = currentPlaylistTableviewFrame
        
    }
    
    /*
     Updates UI components when states or settings change.
     Called whenever states, settings change.
     */
    func updateUI () {
        
        /*
         Update minimzed player view overlay button with appropriate play or pause button */
        if playerView.playerState == YouTubePlayerState.Playing {
            minimizedPlayerViewOverlayButton.isSelected = false
        } else if playerView.playerState == YouTubePlayerState.Paused {
            minimizedPlayerViewOverlayButton.isSelected = true
        }
        
        currentTimeLabel.frame = CGRect(x: 10.0, y: playerOverlayView.frame.size.height - 21.0 - 25.0,
                                        width: 42, height: 21)
        durationLabel.frame = CGRect(x: screenWidth - 10.0 - 42.0, y: playerOverlayView.frame.size.height - 21.0 - 25.0, width: 42.0, height: 21.0)
        
        minimizedPlayerViewOverlayButton.isHidden = !isPlayerViewMinimized
        prevButton.isHidden = !isPlayerViewMinimized
        nextButton.isHidden = !isPlayerViewMinimized
        minimizePlayerViewButton.isHidden = isPlayerViewMinimized
        
        // playerOverlayView.isHidden = isYouTubePlayerViewMinimized
        
        linearTimeProgressBar.isHidden = isPlayerViewMinimized
        circularTimeProgressBar.isHidden = !isPlayerViewMinimized
        
        circularTimeProgressBar.frame.size = circularProgressBarFrameSize
        circularTimeProgressBar.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        
        minimizedPlayerViewOverlayButton.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        prevButton.center = previousButtonCenter
        nextButton.center = nextButtonCenter
        
        /* set hiearchy */
        view.bringSubview(toFront: currentPlaylistTableview)
        view.bringSubview(toFront: playerView)
        view.bringSubview(toFront: playerViewGestureHandlerView)
        view.bringSubview(toFront: playerOverlayView)
        view.bringSubview(toFront: repeatButton)
        view.bringSubview(toFront: minimizePlayerViewButton)
        view.bringSubview(toFront: prevButton)
        view.bringSubview(toFront: nextButton)
        view.bringSubview(toFront: minimizedPlayerViewOverlayButton)
        view.bringSubview(toFront: linearTimeProgressBar)
        
        playerOverlayView.frame = rectangularFullYouTubePlayerViewFrame
    }
    
    /* update UI with scale factor */
    func updateUI(withScale scaleFactor: CGFloat, toState : YouTubePlayerViewSizeState) {
        
        // playerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_CornerRadius)
        // playerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        
        let reverseScaleFactor = 1 - 0.5 * scaleFactor
        let scale = CGAffineTransform.init(scaleX: reverseScaleFactor, y: reverseScaleFactor)
        let scaledTransform = scale.concatenating(CGAffineTransform.init(translationX: -(playerViewGestureHandlerView.bounds.width / 4 * scaleFactor),
                                                                         y: -(playerViewGestureHandlerView.bounds.height / 4 * scaleFactor)))
        
        playerViewGestureHandlerView.transform = scaledTransform
        
        playerView.layer.transform =  CATransform3DMakeAffineTransform(scaledTransform)
        playerViewCurrentTransformScale = playerView.layer.transform
        
        playerViewGestureHandlerView.layer.cornerRadius = scaleFactor * fullYouTubePlayerCornerRadius
        playerView.layer.cornerRadius = scaleFactor * fullYouTubePlayerCornerRadius
        
        // TODO: Need to fix it still.
        playerViewGestureHandlerView.layer.bounds.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width)
        
        
        
        let s = (1 - 0.5 * scaleFactor)
        
        let x = (screenWidth / 2.0) - ( playerViewGestureHandlerView.layer.bounds.width) / 2.0 * s
        // + (screenWidth - fullYouTubePlayerViewOverlayView.layer.bounds.width) / 2.0 * s
        
        print("scaledWidth = \(playerViewGestureHandlerView.bounds.width * (1 ))")
        
        playerViewGestureHandlerView.frame.origin.x = x
        playerViewGestureHandlerView.frame.origin.y = screenHeight * scaleFactor
        
        
        CATransaction.begin()
        
        
        /* change position to bottom center */
        let movePositionToBottomCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToBottomCenterAnimation.toValue = playerViewGestureHandlerView.center
        movePositionToBottomCenterAnimation.duration = 0.00001
        movePositionToBottomCenterAnimation.isRemovedOnCompletion = false
        movePositionToBottomCenterAnimation.fillMode = kCAFillModeForwards
        playerView.layer.add(movePositionToBottomCenterAnimation, forKey: "movePositionToBottomCenterAnimationInUpdateUI")
        
        let squareBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        squareBoundsSizeWidthAnimation.toValue = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width)
        squareBoundsSizeWidthAnimation.duration = 0.00001
        squareBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        squareBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        playerView.layer.add(squareBoundsSizeWidthAnimation, forKey: "squareBoundsSizeWidthAnimationInUpdateUI")
        CATransaction.commit()
        
        
        // youtubePlayerView.layer.frame.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width) // glitches!
        
        
        // youtubePlayerView.frame.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width) // glitches
        // youtubePlayerView.bounds.size.width = screenWidth - scaleFactor * (screenWidth - squareFullYouTubePlayerSize.width) // Glitches!
        
        // youtubePlayerView.layer.bounds.size.width = screenWidth - scaleFactor * ((screenWidth - squareFullYouTubePlayerSize.width)) // Glitches!
        
        print("fullYouTubePlayerViewOverlayView.layer.bounds.size = \(playerViewGestureHandlerView.layer.bounds.size)")
        
        
        print("\(scaleFactor) // \(reverseScaleFactor)")
        
        /* alpha for UIViews that are most visible when player view is maximized */
        let maximizedScaledAlpha = 3.3 * reverseScaleFactor - 2.3
        
        /* alpha for UIViews that are most visible when player view is minimized */
        let minimizedScaledAlpha = 1.4 * scaleFactor - 0.4 // (1.0 / 0.7 * (scaleFactor - 1.0)) + 1.0
        
        print("maximizedScaledAlpha = \(maximizedScaledAlpha)")
        print("minimizedScaledAlpha = \(minimizedScaledAlpha)")
        
        /* playerOverlayView will be visible when full mode. */
        playerOverlayView.alpha = maximizedScaledAlpha
        
        // MARK: REMOVE
        currentPlaylistTableview.alpha = 0.0
        // currentPlaylistTableview.alpha = maximizedScaledAlpha
        
        /* linearTimeProgressBar will be visible when full mode. */
        linearTimeProgressBar.isHidden = false
        linearTimeProgressBar.alpha = maximizedScaledAlpha
        
        /* circularTimeProgressBar won't be visible till scaleFactor reaches 0.3 */
        circularTimeProgressBar.isHidden = false
        circularTimeProgressBar.alpha = minimizedScaledAlpha
        
    }
    
    /* called repeatedly via updateVideoTimeInfoTimer. Updates the time passed of video */
    func updateVideoTimeInfo ()
    {
        currentTimeLabel.text = playerView.getCurrentTimeFormattedString()
        durationLabel.text = playerView.getDurationFormattedString()
        linearTimeProgressBar.setValue(playerView.getTimePercentage(), animated: true)
        circularTimeProgressBar.setValue(playerView.getTimePercentage(), animated: true)
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
            self.isPlayerViewMinimized = true
            self.updateUI()
            self.isChangingYouTubePlayerViewSize = false
            self.startPlayerViewSpinningAnimation()
            self.playerViewSizeState = YouTubePlayerViewSizeState.minimized
            self.playerViewCurrentCornerRadius = fullYouTubePlayerCornerRadius
            self.overlayViewCurrentCornerRadius = minimizedYouTubePlayerCornerRadius
            
            self.playerViewCurrentTransformScale = minimizedYouTubePlayerViewTransformScale
            // self.playerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
            self.playerView.layer.transform = minimizedYouTubePlayerViewTransformScale
            
            self.playerView.layer.position = minimizedSizeBottomCenterYouTubePlayerCenterPoint
            self.playerView.layer.cornerRadius = fullYouTubePlayerCornerRadius
            self.playerViewGestureHandlerView.layer.cornerRadius = minimizedYouTubePlayerCornerRadius
            // self.youtubePlayerView.layer.bounds.size.width = squareFullYouTubePlayerSize.width
            // self.youtubePlayerView.layer.bounds.size.height = squareFullYouTubePlayerSize.height
            
            self.playerViewGestureHandlerView.frame = minimizedSizeBottomCenterYouTubePlayerFrame
            print("overlayView.frame = \(self.playerViewGestureHandlerView.frame)")
            print("expected = \(minimizedSizeBottomCenterYouTubePlayerFrame)")
        }
        
        // playerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        
        /* transformScaleAnimation - shrink size animation */
        let transformScaleAnimation = CABasicAnimation(keyPath: "transform")
        transformScaleAnimation.fromValue = playerViewCurrentTransformScale
        transformScaleAnimation.toValue = minimizedYouTubePlayerViewTransformScale
        transformScaleAnimation.duration = changeSizeAnimationDuration
        transformScaleAnimation.isRemovedOnCompletion = false
        transformScaleAnimation.fillMode = kCAFillModeForwards
        transformScaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(transformScaleAnimation, forKey: YouTubePlayerViewAnimation_TransformScale)
        
        /* change position to bottom center */
        let movePositionToBottomCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToBottomCenterAnimation.fromValue = playerViewGestureHandlerView.center // from wherever the current position is since the player view moves exactly the same as the overlay view.
        movePositionToBottomCenterAnimation.toValue = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        movePositionToBottomCenterAnimation.duration = changeSizeAnimationDuration
        movePositionToBottomCenterAnimation.isRemovedOnCompletion = false
        movePositionToBottomCenterAnimation.fillMode = kCAFillModeForwards
        movePositionToBottomCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(movePositionToBottomCenterAnimation, forKey: YouTubePlayerViewAnimation_Position)
        
        /* cornerRadius to make youtube player view shape into circular */
        let youtubePlayerViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        youtubePlayerViewCornerRadiusAnimation.fromValue = playerViewCurrentCornerRadius
        youtubePlayerViewCornerRadiusAnimation.toValue = fullYouTubePlayerCornerRadius
        youtubePlayerViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // youtubePlayerViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // youtubePlayerViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        youtubePlayerViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(youtubePlayerViewCornerRadiusAnimation, forKey: YouTubePlayerViewAnimation_CornerRadius)
        
        /* cornerRadius to make overlay view shape into circular */
        let overlayViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        overlayViewCornerRadiusAnimation.toValue = minimizedYouTubePlayerCornerRadius
        overlayViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // overlayViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // overlayViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        overlayViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerViewGestureHandlerView.layer.add(overlayViewCornerRadiusAnimation, forKey: MinimizeYouTubePlayerOverlayViewAnimation_CornerRadius)
        
        
        /* squraeBoundsAnimation - make size into square to make it into perfect circle.
         If I don't change the size to a square, then the shape will be changed into an oval. */
        let squareBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        squareBoundsSizeWidthAnimation.toValue = squareFullYouTubePlayerSize.width
        squareBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        squareBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        squareBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        squareBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(squareBoundsSizeWidthAnimation,
                             forKey: YouTubePlayerViewAnimation_BoundsSizeWidth)
        
        /* squraeBoundsAnimation - make size into square to make it into perfect circle.
         If I don't change the size to a square, then the shape will be changed into an oval. */
        let squareBoundsSizeHeightAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        squareBoundsSizeHeightAnimation.toValue = squareFullYouTubePlayerSize.height
        squareBoundsSizeHeightAnimation.duration = changeSizeAnimationDuration
        squareBoundsSizeHeightAnimation.isRemovedOnCompletion = false
        squareBoundsSizeHeightAnimation.fillMode = kCAFillModeForwards
        squareBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(squareBoundsSizeHeightAnimation, forKey: YouTubePlayerViewAnimation_BoundsSizeHeight)
        
        /* keep youtube video at horizontal center */
        let keepYouTubeInHorizontalCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInHorizontalCenterAnimation.toValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInHorizontalCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInHorizontalCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInHorizontalCenterAnimation.fillMode = kCAFillModeForwards
        keepYouTubeInHorizontalCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(keepYouTubeInHorizontalCenterAnimation, forKey: YouTubePlayerViewAnimation_BoundsOriginX)
        
        /* keep youtube video at vertical center */
        let keepVideoInVerticalCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.y")
        keepVideoInVerticalCenterAnimation.toValue = 0.0
        keepVideoInVerticalCenterAnimation.duration = changeSizeAnimationDuration
        keepVideoInVerticalCenterAnimation.isRemovedOnCompletion = false
        keepVideoInVerticalCenterAnimation.fillMode = kCAFillModeForwards
        keepVideoInVerticalCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(keepVideoInVerticalCenterAnimation, forKey: YouTubePlayerViewAnimation_BoundsOriginY)
        
        isChangingYouTubePlayerViewSize = true
        
        CATransaction.commit()
        
        
        /* animate fullYouTubePlayerViewOverlayView */
        UIView.animate(withDuration: changeSizeAnimationDuration,
                       delay: 0.0,
                       options: UIViewAnimationOptions.curveEaseOut ,
                       animations: {
                        self.playerViewGestureHandlerView.frame = minimizedSizeBottomCenterYouTubePlayerFrame
                        self.playerOverlayView.alpha = 0.0
                        self.currentPlaylistTableview.alpha = 0.0
                        self.linearTimeProgressBar.alpha = 0.0
                        self.circularTimeProgressBar.alpha = 1.0
        }) { (completed : Bool) in
            self.currentPlaylistTableview.isHidden = true
            self.linearTimeProgressBar.isHidden = true
            self.currentPlaylistTableview.isHidden = true
        }
        
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
            self.isPlayerViewMinimized = false
            self.updateUI()
            self.isChangingYouTubePlayerViewSize = false
            self.playerViewSizeState = YouTubePlayerViewSizeState.fullScreen
            self.playerView.layer.cornerRadius = 0.0
            self.playerViewCurrentCornerRadius = 0.0
            self.playerViewGestureHandlerView.layer.cornerRadius = 0.0
            self.overlayViewCurrentCornerRadius = 0.0
            self.playerViewCurrentTransformScale = maximizedYouTubePlayerViewTransformScale
            self.playerView.layer.transform = maximizedYouTubePlayerViewTransformScale
            self.stopPlayerViewSpinningAnimation()
        }
        
        // playerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_TransformScale)
        // playerView.layer.removeAnimation(forKey: YouTubePlayerViewAnimation_CornerRadius)
        
        let transformScaleAnimation = CABasicAnimation(keyPath: "transform")
        transformScaleAnimation.fromValue = playerViewCurrentTransformScale
        // minimizedYouTubePlayerViewTransformScale
        
        transformScaleAnimation.toValue = maximizedYouTubePlayerViewTransformScale
        transformScaleAnimation.duration = changeSizeAnimationDuration
        transformScaleAnimation.isRemovedOnCompletion = false
        transformScaleAnimation.fillMode = kCAFillModeForwards
        transformScaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(transformScaleAnimation, forKey: MaximizeYouTubePlayerViewAnimation_TransformScale)
        
        /* change position to top center */
        let movePositionToTopCenterAnimation = CABasicAnimation(keyPath: "position")
        movePositionToTopCenterAnimation.toValue = fullSizeTopYouTubePlayerCenterPoint
        movePositionToTopCenterAnimation.duration = changeSizeAnimationDuration
        movePositionToTopCenterAnimation.isRemovedOnCompletion = false
        movePositionToTopCenterAnimation.fillMode = kCAFillModeForwards
        movePositionToTopCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(movePositionToTopCenterAnimation, forKey: MaximizeYouTubePlayerViewAnimation_TopCenterPosition)
        
        /* cornerRadius for youtubePlayerView */
        let youtubePlayerViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        youtubePlayerViewCornerRadiusAnimation.fromValue = playerViewCurrentCornerRadius
        youtubePlayerViewCornerRadiusAnimation.toValue = 0.0
        youtubePlayerViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // youtubePlayerViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // youtubePlayerViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        youtubePlayerViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(youtubePlayerViewCornerRadiusAnimation, forKey: "cornerRadius")
        
        /* cornerRadius for overlayView */
        let overlayViewCornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
        overlayViewCornerRadiusAnimation.fromValue = overlayViewCurrentCornerRadius
        overlayViewCornerRadiusAnimation.toValue = 0.0
        overlayViewCornerRadiusAnimation.duration = changeSizeAnimationDuration
        // overlayViewCornerRadiusAnimation.isRemovedOnCompletion = false
        // overlayViewCornerRadiusAnimation.fillMode = kCAFillModeForwards
        overlayViewCornerRadiusAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerViewGestureHandlerView.layer.add(overlayViewCornerRadiusAnimation, forKey: "cornerRadius")
        
        /* horizontal rectuangular boundsAnimation */
        let rectangularBoundsSizeWidthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        rectangularBoundsSizeWidthAnimation.fromValue = squareFullYouTubePlayerSize.width
        rectangularBoundsSizeWidthAnimation.toValue = rectangularFullYouTubePlayerViewFrame.size.width
        rectangularBoundsSizeWidthAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeWidthAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeWidthAnimation.fillMode = kCAFillModeForwards
        rectangularBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(rectangularBoundsSizeWidthAnimation,
                             forKey: "squareBoundsSizeWidthAnimation")
        
        /* vertical rectuangular boundsAnimation */
        let rectangularBoundsSizeHeightAnimation = CABasicAnimation(keyPath: "bounds.size.height")
        rectangularBoundsSizeHeightAnimation.fromValue = squareFullYouTubePlayerSize.height
        rectangularBoundsSizeHeightAnimation.toValue = rectangularFullYouTubePlayerViewFrame.height
        rectangularBoundsSizeHeightAnimation.duration = changeSizeAnimationDuration
        rectangularBoundsSizeHeightAnimation.isRemovedOnCompletion = false
        rectangularBoundsSizeHeightAnimation.fillMode = kCAFillModeForwards
        rectangularBoundsSizeWidthAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(rectangularBoundsSizeHeightAnimation,
                             forKey: "squareBoundsSizeHeightAnimation")
        
        /* keep youtube video in center */
        let keepYouTubeInCenterAnimation = CABasicAnimation(keyPath: "bounds.origin.x")
        keepYouTubeInCenterAnimation.fromValue = youtubePlayerViewAnimationCenterPointX
        keepYouTubeInCenterAnimation.toValue = 0.0
        keepYouTubeInCenterAnimation.duration = changeSizeAnimationDuration
        keepYouTubeInCenterAnimation.isRemovedOnCompletion = false
        keepYouTubeInCenterAnimation.fillMode = kCAFillModeForwards
        keepYouTubeInCenterAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        playerView.layer.add(keepYouTubeInCenterAnimation, forKey: "keepInCenter")
        
        CATransaction.commit()
        self.isChangingYouTubePlayerViewSize = true
        
        /* animate fullYouTubePlayerViewOverlayView and circularTimeProgressBar */
        
        UIView.animate(withDuration: changeSizeAnimationDuration, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.playerOverlayView.frame = rectangularFullYouTubePlayerOverlayViewFrame
            self.playerViewGestureHandlerView.frame = rectangularFullYouTubePlayerOverlayViewFrame
            self.playerOverlayView.alpha = 1.0
            // self.currentPlaylistTableview.alpha = 1.0
            self.currentPlaylistTableview.alpha = 0.0
            self.linearTimeProgressBar.alpha = 1.0
            self.circularTimeProgressBar.alpha = 0.0
        }) { (completed : Bool) in
            self.currentPlaylistTableview.isHidden = false
            self.linearTimeProgressBar.isHidden = false
            self.circularTimeProgressBar.isHidden = true
        }
        
    }
    
    /* spins player view is currently playing. */
    func startPlayerViewSpinningAnimation () {
        /* if youtube video is not playing, don't spin */
        if playerView.playerState != YouTubePlayerState.Playing {
            return
        }
        
        let spinningAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        spinningAnimation.toValue = Double.pi * 2
        spinningAnimation.repeatCount = .infinity
        spinningAnimation.duration = (CFTimeInterval(Float(1.0) / minimizedYouTubePlayerViewRotationSpeed)) * 0.75
        spinningAnimation.speed = minimizedYouTubePlayerViewRotationSpeed
        spinningAnimation.isCumulative = true
        playerView.layer.add(spinningAnimation, forKey: "spinningAnimation")
    }
    
    
    /* stops  */
    func stopPlayerViewSpinningAnimation () {
        playerView.layer.removeAnimation(forKey: "spinningAnimation")
    }
    
    /* paused playerView spinning animation */
    func pausePlayerViewSpinningAnimation () {
        pauseLayerAnimation(layer: playerView.layer)
    }
    
    /* resume playerView spinning animation */
    func resumePlayerViewSpinningAnimation () {
        resumeLayerAnimation(layer: playerView.layer)
    }
    
    /*
     Animates the overlay image view with given image
     Starts with the fromRect and becomes the toRect during animation
     */
    func animateOverlayWithImage(image : UIImage, fromRect : CGRect, toRect : CGRect, withDuration duration : TimeInterval)
    {
        overlayImageView.image = image
        overlayImageView.frame = fromRect
        
        overlayImageView.alpha = 1.0
        overlayImageView.isHidden = false
        UIView.animate(withDuration: duration, delay: 0.0,
                       options: UIViewAnimationOptions.curveEaseInOut,
                       animations: {
                        self.overlayImageView.frame = toRect
                        self.overlayImageView.alpha = 0.0
        }, completion: { (completed : Bool) in
            self.overlayImageView.isHidden = true
            self.overlayImageView.frame = fromRect;
        })
    }
    
    // MARK: YouTube Video functions
    /*
     function loadVideo sets up the YouTubePlayer view's parameters and gives the youtube video's id
     */
    func loadVideo()
    {
        /* youtube player's variables */
        playerView.playerVars = [
            "playsinline": "1" as AnyObject,
            "controls": "0" as AnyObject,
            "showinfo": "0" as AnyObject,
            "modestbranding" : "0" as AnyObject,
            "disablekb" : "1" as AnyObject,
            "rel" : "0" as AnyObject
        ]
        
        /* load video with youtube video's id. */
        // youtubePlayerView.loadVideoID("PT2_F-1esPk") // chainsmokers closer original video
        playerView.loadVideoID("zu4GOlrFDh4")
        // playerView.loadVideoID("OcPRNIycl7U") // minions
        // playerView.loadVideoID("WsptdUFthWI") // chainsmokers cover
        // test rectangle - wM0HvuP5Aps
    }
    
    // MARK: YouTubePlayer delegate
    func playerReady(_ videoPlayer: YouTubePlayerView) {
        if videoPlayer == playerView && !didAutoplayPreviously {
            self.playYouTubePlayerView()
        }
    }
    
    /*
     NOTE: UIAlertView - you can play the music by swiping up.
     - when the music stops, this delegate method is being called
     */
    func playerStateChanged(_ videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        if videoPlayer.playerState == YouTubePlayerState.Playing
        {
            if isPlayerViewMinimized
            {
                minimizedPlayerViewOverlayButton.isSelected = false
                resumePlayerViewSpinningAnimation()
            }
            else // full
            {
                
            }
        } else if videoPlayer.playerState == YouTubePlayerState.Paused
        {
            if isPlayerViewMinimized
            {
                minimizedPlayerViewOverlayButton.isSelected = true
                pausePlayerViewSpinningAnimation()
            }
            else // full
            {
                
            }
        }
    }
    
    /* user taps this button to minimize youtube player view */
    @IBAction func minimizePlayerViewButtonTapped(_ sender: UIButton)
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
    
    @IBAction func repeatButtonTapped(_ sender: RepeatButton)
    {
        sender.tapped()
    }
    
    /*
     If the youtube player view is ready, play it.
     Else, pause it.
     */
    func playYouTubePlayerView ()
    {
        if playerView.ready {
            if playerView.playerState != YouTubePlayerState.Playing {
                playerView.play()
            } else {
                playerView.pause()
            }
        }
    }
    
    
    // MARK: UIGestureRecognizer handling functions
    /*
     Reduce size of youtube player view as user pans the youtube player view to the bottom.
     */
    @IBAction func handlePanGestureRecognizer(_ sender: UIPanGestureRecognizer)
    {
        if sender.state == .began {
            let velocity = sender.velocity(in: nil)
            print("velocity = \(velocity)")
            if velocity.y > 0
            {
                if playerViewSizeState == .minimized
                {
                    return
                }
                else
                {
                    /* downwards swipe */
                    youtubePlayerOverlayViewPanGestureDirection = YouTubePlayerViewOverlayDirection.down
                }
            }
            else
            {
                /* upwards swipe */
                youtubePlayerOverlayViewPanGestureDirection = YouTubePlayerViewOverlayDirection.up
            }
            isUserPanningPlayerOverlayView = true
        }
        
        stopPlayerViewSpinningAnimation()
        
        var finalState = YouTubePlayerViewSizeState.fullScreen
        switch playerViewSizeState
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
            playerViewSizeState = finalState
            
            /*
             animate()
             didEndedSwipe(toState: youtubePlayerViewSizeState)
             if youtubePlayerViewSizeState == .hidden {
             // self.videoPlayer.pause()
             }
             */
            isUserPanningPlayerOverlayView = false
            if youtubePlayerOverlayViewPanGestureDirection == YouTubePlayerViewOverlayDirection.down {
                minimizeYouTubePlayerViewAnimation()
            } else {
                maximizeYouTubePlayerViewAnimation()
            }
        }
        
    }
    
    /* called when value of linearTimeProgressBar changed */
    func linearTimeProgressBarValueChangec(_ sender : UISlider)
    {
        let seconds = sender.value * playerView.getDuration()
        playerView.seekTo(seconds, seekAhead: true)
    }
    
    /*
     single tap to play or pause
     */
    @IBAction func handleSingleTapGestureRecognizerOnPlayerView(_ sender: UITapGestureRecognizer)
    {
        playerOverlayView.frame = rectangularFullYouTubePlayerViewFrame
        print("playerOverlayView.frame > \(playerOverlayView.frame)")
        if playerView.playerState == YouTubePlayerState.Playing
        {
            /* video currently playing. user tapped to pause */
            playerView.pause()
            
            /* animate appropriate to video size */
            if isPlayerViewMinimized // minimized
            {
                // minimizedPlayerViewOverlayButton.isSelected = true
                // pausePlayerViewSpinningAnimation()
            }
            else // full size
            {
                minimizedPlayerViewOverlayButton.isSelected = false
                
                let fromSize : CGFloat = 125.0
                let toSize : CGFloat = 200.0
                
                /* animation for playing */
                let fromRect = CGRect(x: screenWidth/2.0 - fromSize / 2.0,
                                      y: rectangularFullYouTubePlayerViewFrame.size.height / 2.0 - fromSize / 2.0,
                                      width: fromSize, height: fromSize)
                let toRect = CGRect(x: screenWidth/2.0 - toSize / 2.0,
                                    y: rectangularFullYouTubePlayerViewFrame.size.height / 2.0 - toSize / 2.0,
                                    width: toSize, height: toSize)
                
                animateOverlayWithImage(image: #imageLiteral(resourceName: "Pause") , fromRect: fromRect, toRect: toRect, withDuration: 1.0)
            }
        }
        else if playerView.playerState == YouTubePlayerState.Paused
            || playerView.playerState == .Ended
        {
            playerView.play()
            
            /* update UI depending on  */
            if isPlayerViewMinimized // minimized
            {
                // minimizedPlayerViewOverlayButton.isSelected = false
                // resumePlayerViewSpinningAnimation ()
            }
            else // full size
            {
                /* full youtube player view. currently playing. user tapped to pause */
                
                let fromSize : CGFloat = 125.0
                let toSize : CGFloat = 200.0
                
                /* animation for playing */
                let fromRect = CGRect(x: screenWidth/2.0 - fromSize / 2.0,
                                      y: rectangularFullYouTubePlayerViewFrame.size.height / 2.0 - fromSize / 2.0,
                                      width: fromSize, height: fromSize)
                let toRect = CGRect(x: screenWidth/2.0 - toSize / 2.0,
                                    y: rectangularFullYouTubePlayerViewFrame.size.height / 2.0 - toSize / 2.0,
                                    width: toSize, height: toSize)
                
                animateOverlayWithImage(image: #imageLiteral(resourceName: "play_icon_white_half") ,
                                        fromRect: fromRect, toRect: toRect, withDuration: 1.0)
            }
        }
    }
    
    
    /* Whenever a user likes a video, hear animation will appear */
    @IBAction func handleDoubleTapGestureRecognizerOnYouTubePlayerView(_ sender: UITapGestureRecognizer)
    {
        if  sender.view == playerViewGestureHandlerView
        {
            /*  */
            likeVideo(videoID: "zu4GOlrFDh4")
            /* like animation */
            overlayImageView.isHidden = false
            overlayImageView.image = #imageLiteral(resourceName: "Heart_Red_Emoji")
            FlareView.sharedCenter().flarify(overlayImageView, inParentView: view, with: UIColor.red)
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
    
    // MARK: Gesture Recognizer delegate
    /*
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = panGestureRecognizer.velocity(in: view)
            return abs(velocity.y) > abs(velocity.x)
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer)
        -> Bool
    {
        if gestureRecognizer is UIPanGestureRecognizer
            && otherGestureRecognizer is UITapGestureRecognizer
        {
            return true
        }
        return false
    }
    */
    
    /*
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        print("gestureRecogznier = \( type(of: gestureRecognizer))")
        
        if touch.view == repeatButton {
            return false
        }
        
        if gestureRecognizer == overlayViewPanGestureRecognizer && touch.view != repeatButton
        {
            let velocity = overlayViewPanGestureRecognizer.velocity(in: nil)
            print("yyyy = \(velocity.y)")
            if ( velocity.y > 0
                // && overlayViewPanGestureRecognizer.state == .began
                && isPlayerViewMinimized )
            {
                return false
            }
        }
        else if gestureRecognizer == overlayViewSingleTapGestureRecognizer { // check if it's on screen
            if (touch.view! != playerViewGestureHandlerView) {
                return false
            } else if touch.view == repeatButton {
                repeatButton.tapped()
                return false
            } else if touch.view is UIButton {
                return false
            }
        }
        
        return true
    }
    */
    
    // MARK: UITableView Datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songTableViewCell")!
        return cell
    }
    
    // MARK: UITableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /* load new video */
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
    
    
    
}
