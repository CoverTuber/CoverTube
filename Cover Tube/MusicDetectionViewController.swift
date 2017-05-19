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
        songDetectionButton.layer.cornerRadius = songDetectionButton.frame.size.width / 2.0
        songDetectionButton.clipsToBounds = true
        songDetectionButton.frame.size = CGSize(width: screenWidth * 0.45, height: screenWidth * 0.45)
        songDetectionButton.center = CGPoint(x: screenWidth / 2.0, y: screenHeight / 2.0 + 20.0)
        
        circleLoading.isHidden = true
        circleLoading.center = CGPoint(x: screenWidth / 2.0, y: screenHeight / 2.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        songDetectionButton.clipsToBounds = true
        songDetectionButton.layer.cornerRadius = 15.0
    }
    

    func handleResult(_ result: String, resType: ACRCloudResultType) -> Void
    {
        DispatchQueue.main.async {
            // resultView.text = result;
            print("handleResult -> result = \(result)")
            self.client?.stopRecordRec()
            self.startRecognition = false
            self.songDetectionButton.setTitle("😃", for: UIControlState.normal)
            
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
        circleLoading.isHidden = startRecognition
        if startRecognition {
            /* stop recognition */
            client?.stopRecordRec()
            circleLoading.stop()
        } else {
            /* start recognition */
            client?.startRecordRec()
            circleLoading.start()
            songDetectionButton.setTitle("?", for: UIControlState.normal)
            showStatusLineNotification(title: "", bodyText: "Listening... 👂🎶", duration: 2.0, backgroundColor: UIColor.purple, foregroundColor: UIColor.white)
        }
        
        startRecognition = !startRecognition
    }

}
