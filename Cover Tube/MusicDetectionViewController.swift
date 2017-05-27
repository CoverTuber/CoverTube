//
//  MusicDetectionViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/13/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class MusicDetectionViewController: UIViewController
{
    @IBOutlet weak var circleLoading: CircleLoading!
    
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
        
        circleLoading.frame = CGRect(x: 0.0, y: 0.0, width: 280.0, height: 280.0)
        circleLoading.isHidden = true
        circleLoading.center = songDetectionButton.center
        circleLoading.stop()
        
        view.bringSubview(toFront: songDetectionButton)
    }
    

    func handleResult(_ result: String, resType: ACRCloudResultType) -> Void
    {
        DispatchQueue.main.async {
            // resultView.text = result;
            print("handleResult -> result = \(result)")
            self.client?.stopRecordRec()
            self.startRecognition = false
            self.songDetectionButton.setTitle("😃", for: UIControlState.normal)
            showMinimizedPlayerView ()
            self.circleLoading.stop()
            
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
                let metadata = resultDictionary!["metadata"] as! [String: Any]
                let music = ((metadata["music"] as! [[String: Any]])[0]) as! [String: Any]
                
                let title = music["title"] as! String
                let artists = music["artists"]
                print("music = \(music)")
                
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
        
        circleLoading.isHidden = startRecognition
        
        if startRecognition {
            /* stop recognition */
            client?.stopRecordRec()
            circleLoading.stop()
            showMinimizedPlayerView ()
            startRecognition = false
        } else {
            /* start recognition */
            client?.startRecordRec()
            startRecognition = true
            circleLoading.start()
            songDetectionButton.setTitle("?", for: UIControlState.normal)
            showStatusLineNotification(title: "", bodyText: "Listening... 👂🎶", duration: 2.0, backgroundColor: UIColor.purple, foregroundColor: UIColor.white)
            hideMinimizedPlayerView()
        }
    }

}
