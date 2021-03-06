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
import ReactiveSwift
import enum Result.NoError

import Lottie

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
    
    @IBOutlet weak var searchButton: UIButton!
    
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
    
    /* search bar to search music */
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var searchResultTableView: UITableView!
    
    /* search model */
    fileprivate let searchModel1 = YoutubeViewModel()
    fileprivate let searchModel2 = MutableItemsViewModel<SearchItem>()
    
    
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
    
    /* whether shuffle is on or not */
    private var isShuffleOn = false
    
    /* current playlist */
    private var currentPlaylist : Playlist? = nil
    
    /* UISearchController used when user searched on search bar */
    private let searchResultController = UISearchController(searchResultsController: nil)
    
    private var viewDidAppearPreviouslyCalled = false
    
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
        
        scrollView.delegate = self
        
        /* setup search result controller */
        setupSearch()
        searchResultController.searchResultsUpdater = self as! UISearchResultsUpdating
        searchResultController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hidePlayerViewAndControlButtons()
        
        didAutoplayPreviously = false
        
        setupBeginningUI()
        
        updateUI()
        
        playerView.frame = rectangularFullYouTubePlayerViewFrame
        playerOverlayView.frame = rectangularFullYouTubePlayerOverlayViewFrame
        playerViewGestureHandlerView.frame = rectangularFullYouTubePlayerOverlayViewFrame
        playerViewSizeState = YouTubePlayerViewSizeState.fullScreen
        
        /* notifications */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playlistSelected(notification:)),
                                               name: TappedPlaylistNotificationName, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.searchBarResignFirstResponder),
                                               name: ResignSearchBarFirstResponderNotificationName,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.hideMinimizedPlayerViewAnimation),
                                               name: HideMinimizedPlayerViewNotificationName,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.showMinimizedPlayerViewAnimation),
                                               name: ShowMinimizedPlayerViewNotificationName,
                                               object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
        
        // hidePlayerViewAndControlButtons()
        
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
        
        
        /* Testing Lottie */
        /*
        let lottieAnimationView = LOTAnimationView(name: "data")
        lottieAnimationView?.frame = CGRect(x: 0.0, y: 0.0, width: 300.0, height: 300.0)
        lottieAnimationView?.contentMode = .scaleAspectFit
        view.addSubview(lottieAnimationView!)
        view.bringSubview(toFront: lottieAnimationView!)
        lottieAnimationView?.loopAnimation = true
        lottieAnimationView?.play()
        */
        
        if !viewDidAppearPreviouslyCalled
        {
            viewDidAppearPreviouslyCalled = true
            redirectToOAuth2Server()
        }
        
        minimizePlayerViewButtonTapped(minimizePlayerViewButton)
        
        if isUserLoggedIn() == false
        {
            /* Just display playlists and hide player view etc */
            hidePlayerViewAndControlButtons()
        }
        hidePlayerViewAndControlButtons()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        circularTimeProgressBar.removeFromSuperview()
        
        /* disable update video time info timer */
        if updateVideoTimeInfoTimer != nil {
            updateVideoTimeInfoTimer!.invalidate()
            updateVideoTimeInfoTimer = nil
        }
        
        NotificationCenter.default.removeObserver(self)
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
        
        /* set up minimized  */
        minimizePlayerViewButton.setTitleColor(lightBlueColor,
                                               for: UIControlState.normal)
        
        /* set up repeat button */
        repeatButton.center = CGPoint(x: screenWidth / 2.0,
                                      y: 8.0 + repeatButton.frame.size.height / 2.0)
        
        /* set up shuffle button */
        shuffleButton.frame.size = CGSize(width: 28.0, height: 28.0)
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
        prevButton.frame.size = previousButtonSize
        prevButton.center = previousButtonCenter
        prevButton.clipsToBounds = true
        prevButton.layer.cornerRadius = previousButtonCornerRadius
        
        /* set up next button */
        nextButton.frame.size = nextButtonSize
        nextButton.center = nextButtonCenter
        nextButton.clipsToBounds = true
        nextButton.layer.cornerRadius = nextButtonCornerRadius
        
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
        let imageView2 = UIImageView(image: #imageLiteral(resourceName: "Blue_Gradient_Background"))
        currentPlaylistTableview.backgroundView = imageView2
        
        /* setup search button */
        searchButton.frame = CGRect(x: screenWidth - 22.0 - 12.0, y: 12.0, width: 22.0, height: 22.0)
        
        /* setup search bar */
        searchBar.frame = CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 44.0)
        
        /* set up search results tableView */
        searchResultTableView.keyboardDismissMode = .onDrag
        searchResultTableView.frame = CGRect(x: 0.0, y: 44.0, width: screenWidth, height: screenHeight - 44.0)
        // searchResultTableView.backgroundColor = UIColor.clear
        
        let imageView1 = UIImageView(image: #imageLiteral(resourceName: "Blue_Gradient_Background"))
        
        imageView1.frame = searchResultTableView.frame
        searchResultTableView.backgroundView = imageView1
        
        
        
        overlayImageView.center.x = screenWidth / 2.0
        
    }
    
    func setupBeginningUI () {
        searchResultTableView.isHidden = true
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
        repeatButton.isHidden = isPlayerViewMinimized
        shuffleButton.isHidden = isPlayerViewMinimized
        searchButton.isHidden = isPlayerViewMinimized
        currentPlaylistTableview.isHidden = isPlayerViewMinimized
        
        // playerOverlayView.isHidden = isYouTubePlayerViewMinimized
        
        linearTimeProgressBar.isHidden = isPlayerViewMinimized
        circularTimeProgressBar.isHidden = !isPlayerViewMinimized
        
        circularTimeProgressBar.frame.size = circularProgressBarFrameSize
        circularTimeProgressBar.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        
        minimizedPlayerViewOverlayButton.center = minimizedSizeBottomCenterYouTubePlayerCenterPoint
        prevButton.center = previousButtonCenter
        nextButton.center = nextButtonCenter
        
        
        /* set hiearchy */
        view.bringSubview(toFront: searchResultTableView)
        view.bringSubview(toFront: searchBar)
        view.bringSubview(toFront: currentPlaylistTableview)
        view.bringSubview(toFront: playerView)
        view.bringSubview(toFront: playerViewGestureHandlerView)
        view.bringSubview(toFront: playerOverlayView)
        view.bringSubview(toFront: repeatButton)
        view.bringSubview(toFront: shuffleButton)
        view.bringSubview(toFront: searchButton)
        view.bringSubview(toFront: minimizePlayerViewButton)
        view.bringSubview(toFront: prevButton)
        view.bringSubview(toFront: nextButton)
        view.bringSubview(toFront: minimizedPlayerViewOverlayButton)
        view.bringSubview(toFront: linearTimeProgressBar)
        
        playerOverlayView.frame = rectangularFullYouTubePlayerViewFrame
        
        /* update shuffle */
        shuffleButton.isSelected = isShuffleOn
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
            
            self.searchBar.isHidden = false
            if self.searchBar.text == nil {
                self.searchResultTableView.isHidden = true
            } else {
                self.searchResultTableView.isHidden = self.searchBar.text!.isEmpty
            }
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
        /*
        playerView.layer.add(squareBoundsSizeWidthAnimation,
                             forKey: YouTubePlayerViewAnimation_BoundsSizeWidth)
        */
        
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
        
        /* prepare for UIView.animate */
        /*
        shuffleButton.isHidden = false
        shuffleButton.alpha = 1.0
        shuffleButton.isHidden = false
        shuffleButton.alpha = 1.0
        */
        
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
                        self.repeatButton.alpha = 0.0
                        self.shuffleButton.alpha = 0.0
                        self.searchButton.alpha = 0.0
        }) { (completed : Bool) in
            self.currentPlaylistTableview.isHidden = true
            self.linearTimeProgressBar.isHidden = true
            self.repeatButton.isHidden = true
            self.shuffleButton.isHidden = true
            self.searchButton.isHidden = true
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
            self.searchBar.isHidden = true
            self.searchResultTableView.isHidden = true
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
        
        /* prepare for UIView.animate */
        currentPlaylistTableview.isHidden = false
        repeatButton.isHidden = false
        repeatButton.alpha = 0.0
        shuffleButton.isHidden = false
        shuffleButton.alpha = 0.0
        searchButton.isHidden = false
        searchButton.alpha = 0.0
        
        UIView.animate(withDuration: changeSizeAnimationDuration, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.playerOverlayView.frame = rectangularFullYouTubePlayerOverlayViewFrame
            self.playerViewGestureHandlerView.frame = rectangularFullYouTubePlayerOverlayViewFrame
            self.playerOverlayView.alpha = 1.0
            self.currentPlaylistTableview.alpha = 1.0
            self.linearTimeProgressBar.alpha = 1.0
            self.circularTimeProgressBar.alpha = 0.0
            self.repeatButton.alpha = 1.0
            self.shuffleButton.alpha = 1.0
            self.searchButton.alpha = 1.0
        }) { (completed : Bool) in
            self.linearTimeProgressBar.isHidden = false
            self.circularTimeProgressBar.isHidden = true
        }
        
    }
    
    /*
     Call this function when hiding minimized palyer view.
     Will pause video, pause spinning animation, hide pre, next, etc buttons at bottom.
     */
    func hideMinimizedPlayerViewAnimation ()
    {
        if playerView.playerState == YouTubePlayerState.Playing {
            playerView.pause()
            pausePlayerViewSpinningAnimation()
        }
        
        searchBar.resignFirstResponder()
        searchBar.isHidden = true
        playerView.isHidden = true
        minimizedPlayerViewOverlayButton.isHidden = true
        prevButton.isHidden = true
        nextButton.isHidden = true
        playerViewGestureHandlerView.isHidden = true
        circularTimeProgressBar.isHidden = true
    }
    
    /*
     Call this function when showing minimized player view.
     will play video, resume spinning animation, show pre, next, etc buttons at bottom
     */
    func showMinimizedPlayerViewAnimation ()
    {
        /* If currently playing, pause and stop spinning animation */
        if playerView.playerState == YouTubePlayerState.Paused {
            playerView.play()
            resumePlayerViewSpinningAnimation()
        }
        
        view.bringSubview(toFront: playerView)
        
        
        searchBar.resignFirstResponder()
        searchBar.isHidden = false
        playerView.isHidden = false
        prevButton.isHidden = false
        nextButton.isHidden = false
        minimizedPlayerViewOverlayButton.isHidden = false
        playerViewGestureHandlerView.isHidden = false
        circularTimeProgressBar.isHidden = false
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
    
    func hidePlayerViewAndControlButtons ()
    {
        
        /* Just display playlists */
        playerView.isHidden = true
        playerOverlayView.isHidden = true
        minimizePlayerViewButton.isHidden = true
        repeatButton.isHidden = true
        shuffleButton.isHidden = true
        searchButton.isHidden = true
        overlayImageView.isHidden = true
        currentTimeLabel.isHidden = true
        durationLabel.isHidden = true
        playerViewGestureHandlerView.isHidden = true
        prevButton.isHidden = true
        minimizedPlayerViewOverlayButton.isHidden = true
        nextButton.isHidden = true
        currentPlaylistTableview.isHidden = true
        linearTimeProgressBar.isHidden = true
        circularTimeProgressBar.isHidden = true
    }
    
    func showPlayerViewAndControlButtons ()
    {
        /* Display playerView and  */
        playerView.isHidden = false
        playerOverlayView.isHidden = false
        minimizePlayerViewButton.isHidden = false
        repeatButton.isHidden = false
        shuffleButton.isHidden = false
        searchButton.isHidden = false
        overlayImageView.isHidden = false
        currentTimeLabel.isHidden = false
        durationLabel.isHidden = false
        playerViewGestureHandlerView.isHidden = false
        prevButton.isHidden = false
        minimizedPlayerViewOverlayButton.isHidden = false
        nextButton.isHidden = false
        currentPlaylistTableview.isHidden = false
        linearTimeProgressBar.isHidden = false
        circularTimeProgressBar.isHidden = false
    }
    
    
    // MARK: YouTube Video functions
    /*
     function loadVideo sets up the YouTubePlayer view's parameters and gives the youtube video's id
     */
    func loadVideo(videoId : String)
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
        // playerView.loadVideoID("zu4GOlrFDh4")
        // playerView.loadVideoID("OcPRNIycl7U") // minions
        playerView.loadVideoID(videoId) // "WsptdUFthWI") // chainsmokers cover
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
    
    @IBAction func shuffledButtonTapped(_ sender: UIButton)
    {
        isShuffleOn = !isShuffleOn
        shuffleButton.isSelected = isShuffleOn
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
    
    
    /* Whenever a user likes a video, animation will appear */
    @IBAction func handleDoubleTapGestureRecognizerOnYouTubePlayerView(_ sender: UITapGestureRecognizer)
    {
        /* if user double tapped full youtube screen */
        if  sender.view == playerViewGestureHandlerView && !isPlayerViewMinimized
        {
            /* like video - user needs to be logged in. */
            YouTube.likeVideo(videoID: playerView.currentVideoID)
            
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
        if tableView == currentPlaylistTableview
        {
            if currentPlaylist == nil {
                return 0
            } else {
                return currentPlaylist!.videos.count
            }
        }
        else // if tableView == searchResultTableView
        {
            return searchModel2.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == currentPlaylistTableview
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "videoTableViewCell") as! VideoTableViewCell
            cell.backgroundColor = UIColor.clear
            let video = currentPlaylist!.videos[indexPath.item]
            
            if let imageURL = URL(string: video.thumbnailMediumURLString ) {
                cell.imageView?.setImageWith(imageURL)
            }
            cell.textLabel?.textColor = UIColor.white
            // cell.textLabel?.font = UIFont(name: "GothamPro", size: 20)!
            cell.textLabel?.text = video.title
            
            return cell
        }
        else // if tableView == searchResultTableView
        {
            let item = searchModel2.items[indexPath.row]
            switch item {
            case .channelItem(let channel):
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath) as! ChannelCell
                cell.textLabel?.textColor = UIColor.white
                cell.backgroundColor = UIColor(red: 77.0 / 255.0 , green: 77.0 / 255.0, blue: 77.0 / 255.0, alpha: 0.5)
                cell.channel = channel
                return cell
            case .videoItem(let video):
                let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.video = video
                cell.backgroundColor = UIColor(red: 77.0 / 255.0 , green: 77.0 / 255.0, blue: 77.0 / 255.0, alpha: 0.5)
                cell.textLabel?.textColor = UIColor.white
                return cell
            }
        }
    }
    
    // MARK: UITableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /* load new video */
        if tableView == searchResultTableView
        {
            let item = self.searchModel2.items[indexPath.row]
            switch item {
            case .channelItem(let channel):
                break
            case .videoItem(let video):
                searchBar.resignFirstResponder()
                maximizeYouTubePlayerViewAnimation()
                loadVideo(videoId: video.id)
                // playerView.loadVideoID(video.id)
                break
            }
        }
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidScroll(_ currentScrollView: UIScrollView) {
        if (currentScrollView == searchResultTableView)
        {
            guard let provider = self.searchModel2.provider.value, !provider.items.value.isEmpty && !provider.isLoadingPage else {
                return
            }
            
            let lastCellIndexPath = IndexPath(row: provider.items.value.count - 1, section: 0)
            if searchResultTableView.cellForRow(at: lastCellIndexPath) == nil {
                return
            }
            
            provider.pageLoader?.startWithFailed {
                [weak self] error in
                showStatusLineErrorNotification(title: "",
                                                bodyText: error.localizedDescription,
                                                duration: 2)
            }
        }
        else // if currentScrollView == self.scrollView
        {
            hidePlayerViewAndControlButtons()
            resignSearchBarFirstResponse()
            let page = currentScrollView.contentOffset.x / screenWidth
            if page == 0 {
                if leftVC is MusicDetectionViewController {
                    let musicDetectionVC = leftVC as! MusicDetectionViewController
                    musicDetectionVC.setupUI()
                }
            }
            else if page == 1 {
                if middleVC is PlaylistViewController {
                    let middlePlaylistVC = middleVC as! PlaylistViewController
                    middlePlaylistVC.playlistCollectionView.reloadData()
                }
            }
        }
    }
    
    
    func switchShuffle () {
        
    }
    
    func playlistSelected ( notification : Notification ) {
        if !(notification.userInfo is [String : Any] ) {
            print("SwipeContainerVC playlistSelected. notificationUserInfo is wrong type")
            return
        }
        
        showPlayerViewAndControlButtons()
        
        if let userInfo = notification.userInfo as? [String : Any]
        {
            if let playlist = userInfo["selectedPlaylist"] as? Playlist
            {
                currentPlaylist = playlist
            }
            
            if let isShuffledPlay = userInfo["shuffledPlay"] {
                isShuffleOn = isShuffledPlay as! Bool
                updateUI()
            }
            
            if currentPlaylist == nil {
                return
            }
            
            if  currentPlaylist!.videos.count == 0 {
                return
            }
            
            showStatusLineNotification(title: "", bodyText: "Playing \(currentPlaylist!.title)", duration: 2, backgroundColor: lightBlueColor, foregroundColor: UIColor.white)
            
            let firstVideo = currentPlaylist!.videos[0]
            
            /* play first video */
            didAutoplayPreviously = false
            playerView.clear()
            playerView.stop()
            // playerView.loadPlaylistID(currentPlaylist!.id)
            // playerView.loadVideoID(firstVideo.videoId)
            loadVideo(videoId: firstVideo.videoId)
            maximizeYouTubePlayerViewAnimation()
            
            currentPlaylistTableview.reloadData()
        }
    }
    
    // MARK: Search functionality
    func setupSearch() {
        searchModel2.mutableProvider <~ self.searchModel1.keyword.signal
            .debounce(0.5, on: QueueScheduler.main)
            .map { keyword -> AnyItemsProvider<SearchItem>? in
                if keyword.isEmpty {
                    return nil
                }
                return AnyItemsProvider { token, limit in
                    let request = Search(.term(keyword, [.video: [.statistics, .contentDetails], .channel: [.statistics]]),
                                         limit: limit,
                                         pageToken: token)
                    return Engine.defaultEngine
                        .search(request)
                        .map { page in (page.items, page.nextPageToken) }
                }
        }
        
        
        
        
        self.searchModel2
            .provider
            .producer
            .flatMap(.latest) {
                provider -> SignalProducer<Void, NoError> in
                if let pageLoader = provider?.pageLoader {
                    return pageLoader
                        .on(failed: {
                            [weak self] error in
                            showStatusLineErrorNotification(title: error.localizedDescription,
                                                            bodyText: "",
                                                            duration: 2)
                        })
                        .flatMapError { _ in .empty }
                }
                return .empty
            }
            .startWithCompleted {}
        
        self.searchModel2
            .provider
            .producer.flatMap(.latest) {
                provider -> SignalProducer<[SearchItem], NoError> in
                guard let provider = provider else {
                    return SignalProducer(value: [])
                }
                
                return provider.items.producer
            }
            .startWithValues {
                [weak self] _ in
                self?.searchResultTableView.isHidden = false
                self?.searchResultTableView.reloadData()
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton)
    {
        minimizeYouTubePlayerViewAnimation()
        searchBar.becomeFirstResponder()
    }
    
    func searchBarResignFirstResponder ()
    {
        searchBar.resignFirstResponder()
    }
    
    public func setSearchBarText (withText text : String)
    {
        searchBar.text = text
    }
}

/*
 Learned about search results updating from
 https://www.raywenderlich.com/113772/uisearchcontroller-tutorial
 */
extension SwipeContainerViewController : UISearchResultsUpdating {
    /*
     Whenever user adds or removes text in search bar.
     UISearchController will inform SwipeContainerVC class of the change via this method.
     */
    func updateSearchResults(for searchController: UISearchController) {
        /*
         Call filter function
         */
    }
}


extension SwipeContainerViewController : UISearchBarDelegate
{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.searchResultTableView.isHidden = true
        }
        else {
            self.searchModel1.keyword.value = "\(searchText) cover music"
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
