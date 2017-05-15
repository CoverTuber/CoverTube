//
//  MusicDetectionViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/13/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class MusicDetectionViewController: UIViewController {
    
    private var start = false
    private var client: ACRCloudRecognition?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        start = false;
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func handleResult(_ result: String, resType: ACRCloudResultType) -> Void
    {
        
        DispatchQueue.main.async {
            // resultView.text = result;
            print(result)
            self.client?.stopRecordRec()
            self.start = false
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

}
