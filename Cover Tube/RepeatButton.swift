//
//  RepeatButton.swift
//  Cover Tube
//
//  Created by June Suh on 5/16/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

enum RepeatButtonState {
    case repeatOff
    case repeatOn       // When user repeats one song infinitely
    case repeatXTimes   // When user repeats one song X times
    
}

class RepeatButton: UIButton {
    
    /* number of repeats */
    var repeatCount : Int64 = 0
    
    /* custom state: off, on (infinite), on (x times) */
    var currentState = RepeatButtonState.repeatOff {
        didSet {
            switch currentState {
            case .repeatOff:
                repeatCount = 0
                repeatLabel?.isHidden = true
            case .repeatOn:
                repeatCount = IntMax.max
                repeatLabel?.isHidden = true
            case .repeatXTimes:
                repeatCount = 3
                repeatLabel?.isHidden = false
            }
            repeatLabel?.text = "\(repeatCount)"
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
        /* set up button's basic settings */
        setImage( #imageLiteral(resourceName: "Repeat_White") , for: UIControlState.normal)
        tintColor = UIColor.white
        
        /* set up button's shadow */
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0.75, height: 0.75)
        layer.shadowOpacity = 0.75
        
        // create repeatLabel
        repeatLabel = UILabel (frame: CGRect(x: 30 - 10, y: 0, width: 17, height: 17 ))
        repeatLabel?.backgroundColor = lightBlueColor
        repeatLabel?.textColor = UIColor.white
        repeatLabel?.layer.masksToBounds = true
        repeatLabel?.layer.cornerRadius = repeatLabel!.frame.width / 2.0
        repeatLabel!.frame.origin = CGPoint(x : -3.0, y : 0.0)
        repeatLabel!.adjustsFontSizeToFitWidth = true
        repeatLabel!.font = UIFont(name: "ArialRoundedMTBold ", size: 6.0)
        repeatLabel!.textAlignment = NSTextAlignment.center
        repeatLabel!.textColor = UIColor.white
        repeatLabel!.text = "\(repeatCount)"
        addSubview(repeatLabel!)
        
        currentState = .repeatOff
    }
    
    /* changes state when tapped */
    func tapped () {
        switch currentState
        {
            case .repeatOff:
                currentState = .repeatOn
            case .repeatOn:
                currentState = .repeatXTimes
            case .repeatXTimes:
                currentState = .repeatOff
        }
    }
    
}
