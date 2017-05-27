//
//  MusicDetectionViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/13/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class MusicDetectionViewController: VideoSplashViewController
{
    @IBOutlet weak var songDetectionButton: UIButton!
    
    private var startRecognition = false
    private var client: ACRCloudRecognition?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        startRecognition = false;
        
        let config = ACRCloudConfig();
        
        config.accessKey = accessKey
        config.accessSecret = accessSecret
        config.host = host
        //if you want to identify your offline db, set the recMode to "rec_mode_local"
        config.recMode = rec_mode_remote;
        config.audioType = "recording";
        config.requestTimeout = 300;
        config.protocol = "https";
        
        config.stateBlock = {[weak self] state in
            self?.handleState(state!);
        }
        
        config.volumeBlock = {[weak self] volume in
            //do some animations with volume
            self?.handleVolume(volume)
        }
        
        config.resultBlock = {[weak self] result, resType in
            self?.handleResult(result!, resType:resType)
        }
        client = ACRCloudRecognition(config: config)
        
        setupBackgroundVideo()
    }
    
    func setupBackgroundVideo ()
    {
        let nsURL = NSURL.init(fileURLWithPath: Bundle.main.path(forResource: "DetectionBackground", ofType: "mp4")! )
        let url = nsURL as URL
        // let url = URL(fileURLWithPath: Bundle.main.path(forResource: "DetectionBackground", ofType: "mp4")!)
        self.videoFrame = view.frame
        self.fillMode = .resizeAspectFill
        self.alwaysRepeat = false
        self.sound = false
        self.startTime = 12.0
        self.duration = 0.0
        self.alpha = 0.0
        self.backgroundColor = UIColor.clear
        self.contentURL = url
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        songDetectionButton.clipsToBounds = true
        songDetectionButton.frame.size = CGSize(width: screenWidth * 0.45, height: screenWidth * 0.45)
        songDetectionButton.center = CGPoint(x: screenWidth / 2.0, y: screenHeight / 2.0 + 20.0)
        songDetectionButton.layer.cornerRadius = songDetectionButton.frame.size.width / 2.0
        
        view.bringSubview(toFront: moviePlayer.view)
        view.bringSubview(toFront: songDetectionButton)
        
        pauseVideo()
        moviePlayer.view.isHidden = true
    }
    

    func handleResult(_ result: String, resType: ACRCloudResultType) -> Void
    {
        DispatchQueue.main.async {
            // resultView.text = result;
            print("handleResult -> result = \(result)")
            self.client?.stopRecordRec()
            self.pauseVideo()
            self.alpha = 0.0
            self.moviePlayer.view.isHidden = true
            self.startRecognition = false
            self.songDetectionButton.setTitle("😃", for: UIControlState.normal)
            showMinimizedPlayerView ()
            
            if result.contains("No result") {
                showStatusLineNotification(title: "", bodyText: "No result", duration: 2, backgroundColor: UIColor.purple, foregroundColor: UIColor.white)
                return
            }
            
            let resultDictionary = convertToDictionary(text: result)
            if resultDictionary == nil {
                showStatusLineNotification(title: "Oops, it's not working", bodyText: "", duration: 2.0, backgroundColor: UIColor.blue, foregroundColor: UIColor.white)
                return
            }
            
            if resultDictionary!["status"] == nil {
                showStatusLineNotification(title: "Oops, it's not working", bodyText: "", duration: 2.0, backgroundColor: UIColor.blue, foregroundColor: UIColor.white)
                return
            }
            
            let statusDictionary = resultDictionary!["status"] as! [String: Any]
            if statusDictionary["msg"] == nil {
                showStatusLineNotification(title: "Oops, it's not working", bodyText: "", duration: 2.0, backgroundColor: UIColor.blue, foregroundColor: UIColor.white)
                return
            }
            
            let statusMessage = statusDictionary["msg"] as! String
            
            if statusMessage == "No result" {
                showStatusLineNotification(title: "Sorry, we can't find it",
                                           bodyText: "",
                                           duration: 2.0,
                                           backgroundColor: UIColor.blue,
                                           foregroundColor: UIColor.white)
                return
            }
            else if statusMessage == "Success" {
                if resultDictionary!["metadata"] == nil {
                    showStatusLineNotification(title: "",
                                               bodyText: "Sorry, we can't find it",
                                               duration: 2.0,
                                               backgroundColor: UIColor.blue,
                                               foregroundColor: UIColor.white)
                }
                
                let metadata = resultDictionary!["metadata"] as! [String: Any]
                
                if ((metadata["music"] as! [[String: Any]]).count == 0) {
                    showStatusLineNotification(title: "",
                                               bodyText: "Sorry, we can't find it",
                                               duration: 2.0,
                                               backgroundColor: UIColor.blue,
                                               foregroundColor: UIColor.white)
                }
                
                let music = ((metadata["music"] as! [[String: Any]])[0]) as! [String: Any]
                
                let title = music["title"] as! String
                let artists = music["artists"]
                
                var artistStr = ""
                if (artists is Array<Dictionary<String, String>>)
                {
                    let artistsArray = artists as! Array<Dictionary<String, String>>
                    if artistsArray.count > 0
                    {
                        if ((artists as! Array<Dictionary<String, String>>)[0])["name"] != nil
                        {
                            artistStr = ((artists as! Array<Dictionary<String, String>>)[0])["name"]!
                        }
                    }
                }
                
                print("music = \(music)")
                
                AppDelegate.getSnapchatSwipeContainerVC()!.setSearchBarText (withText : "\(title) \(artistStr)")
                
                // AppDelegate.getSnapchatSwipeContainerVC().setSearchBarText (withText )
            }
        }
    }
    
    func handleVolume(_ volume: Float) -> Void {
        DispatchQueue.main.async {
            // volumeLabel.text = String(format: "Volume: %f", volume)
        }
    }
    
    func handleState(_ state: String) -> Void
    {
        DispatchQueue.main.async {
            // stateLabel.text = String(format:"State : %@",state)
        }
    }
    
    
    @IBAction func detectionButtonTapped(_ sender: UIButton)
    {
        resignSearchBarFirstResponse()
        
        if startRecognition {
            /* stop recognition */
            pauseVideo()
            self.alpha = 0.0
            moviePlayer.view.isHidden = true
            client?.stopRecordRec()
            // circleLoading.stop()
            showMinimizedPlayerView ()
            startRecognition = false
        } else {
            /* start recognition */
            playVideo()
            moviePlayer.view.isHidden = false
            self.alpha = 1.0
            client?.startRecordRec()
            startRecognition = true
            // circleLoading.start()
            songDetectionButton.setTitle("?", for: UIControlState.normal)
            showStatusLineNotification(title: "", bodyText: "Listening... 👂🎶", duration: 2.0, backgroundColor: UIColor.purple, foregroundColor: UIColor.white)
            hideMinimizedPlayerView()
        }
    }

}
