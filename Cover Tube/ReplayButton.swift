//
//  ReplayButton.swift
//  Cover Tube
//
//  Created by June Suh on 5/16/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

enum ReplayButtonState {
    case replayOff
    case replayOn       // When user replays one song infinitely
    case replayXTimes   // When user replays one song X times
    
}

class ReplayButton: UIButton {
    /* number of repeats */
    var repeatCount : Int64 = 0
    
    /* custom state: off, on (infinite), on (x times) */
    var customState = ReplayButtonState.replayOff {
        didSet {
            switch customState {
            case .replayOff:
                repeatCount = 0
            case .replayOn:
                repeatCount = IntMax.max
            case .replayXTimes: break
            }
        }
    }
    
    fileprivate var repeatLabel : UILabel?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        setup()
    }
    
    // MARK: Private method
    private func setup () {
        // create repeatLabel
        repeatLabel = UILabel (frame: frame.insetBy(dx: 25, dy: 25))
        repeatLabel?.backgroundColor = UIColor.red
        repeatLabel?.layer.masksToBounds = true
        repeatLabel?.layer.cornerRadius = repeatLabel!.frame.width / 2.0
        repeatLabel!.frame.origin = CGPoint(x : 0.0, y : 0.0)
        /*
        repeatLabel?.center = CGPoint(x : self.frame.origin.x + repeatLabel!.frame.width / 2.0,
                                      y : self.frame.origin.y + repeatLabel!.frame.height / 2.0)
        */
        repeatLabel!.textAlignment = NSTextAlignment.center
        repeatLabel!.textColor = UIColor.white
        repeatLabel!.text = "\(repeatCount)"
        addSubview(repeatLabel!)
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
