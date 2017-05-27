//
//  VideoSplashViewController.swift
//  VideoSplash
//
//  Created by Toygar Dündaralp on 8/3/15.
//  Copyright (c) 2015 Toygar Dündaralp. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

public enum ScalingMode {
  case resize
  case resizeAspect
  case resizeAspectFill
}

open class VideoSplashViewController: UIViewController {

  let moviePlayer = AVPlayerViewController()
  fileprivate var moviePlayerSoundLevel: Float = 1.0
  open var contentURL: URL = URL.init(fileURLWithPath: "") {
    didSet {
      setMoviePlayer(contentURL)
    }
  }

  open var videoFrame: CGRect = CGRect()
  open var startTime: CGFloat = 0.0
  open var duration: CGFloat = 0.0
  open var backgroundColor: UIColor = UIColor.black {
    didSet {
      view.backgroundColor = backgroundColor
    }
  }
  open var sound: Bool = true {
    didSet {
      if sound {
        moviePlayerSoundLevel = 1.0
      }else{
        moviePlayerSoundLevel = 0.0
      }
    }
  }
  open var alpha: CGFloat = CGFloat() {
    didSet {
      moviePlayer.view.alpha = alpha
    }
  }
  open var alwaysRepeat: Bool = true {
    didSet {
      if alwaysRepeat {
        NotificationCenter.default.addObserver(self,
          selector: #selector(VideoSplashViewController.playerItemDidReachEnd),
          name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
          object: moviePlayer.player?.currentItem)
      }
    }
  }
  open var fillMode: ScalingMode = .resizeAspectFill {
    didSet {
      switch fillMode {
      case .resize:
        moviePlayer.videoGravity = AVLayerVideoGravityResize
      case .resizeAspect:
        moviePlayer.videoGravity = AVLayerVideoGravityResizeAspect
      case .resizeAspectFill:
        moviePlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      }
    }
  }
    
   open var restartForeground: Bool = false {
        didSet {
            if restartForeground {
                NotificationCenter.default.addObserver(self,
                    selector: #selector(VideoSplashViewController.playerItemDidReachEnd),
                    name: NSNotification.Name.UIApplicationWillEnterForeground,
                    object: nil)
            }
        }
    }

  override open func viewDidAppear(_ animated: Bool) {
    moviePlayer.view.frame = videoFrame
    moviePlayer.view.backgroundColor = self.backgroundColor;
    moviePlayer.showsPlaybackControls = false
    moviePlayer.view.isUserInteractionEnabled = false
    view.addSubview(moviePlayer.view)
    view.sendSubview(toBack: moviePlayer.view)
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  }

  fileprivate func setMoviePlayer(_ url: URL){
    let videoCutter = VideoCutter()
    videoCutter.cropVideoWithUrl(
      videoUrl: url,
      startTime: startTime,
      duration: duration) { (videoPath, error) -> Void in
      if let path = videoPath as URL? {
        let priority = DispatchQueue.GlobalQueuePriority.default
        DispatchQueue.global(priority: priority).async {
          DispatchQueue.main.async {
            self.moviePlayer.player = AVPlayer(url: path)
            self.moviePlayer.player?.addObserver(
              self,
              forKeyPath: "status",
              options: .new,
              context: nil)
            self.moviePlayer.player?.play()
            self.moviePlayer.player?.volume = self.moviePlayerSoundLevel
          }
        }
      }
    }
  }

  open override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?) {
      guard let realObject = object, object != nil else {
        return
      }
      if !(realObject is AVPlayer)
      {
        return
      }
      if realObject as? AVPlayer != self.moviePlayer.player || keyPath! != "status" {
        return
      }
      if self.moviePlayer.player?.status == AVPlayerStatus.readyToPlay{
        self.movieReadyToPlay()
      }
  }

  deinit{
	self.moviePlayer.player?.removeObserver(self, forKeyPath: "status")
    NotificationCenter.default.removeObserver(self)

  }

  // Override in subclass
  open func movieReadyToPlay() { }

  override open func viewDidLoad() {
    super.viewDidLoad()
  }

  override open func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  func playerItemDidReachEnd() {
    moviePlayer.player?.seek(to: kCMTimeZero)
    moviePlayer.player?.play()
  }

  func playVideo() {
    moviePlayer.player?.play()
  }

  func pauseVideo() {
    moviePlayer.player?.pause()
  }
}
