//
//  PlaylistCollectionViewCell.swift
//  Cover Tube
//
//  Created by June Suh on 5/17/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class PlaylistCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var shufflePlayButton: ProfileButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shufflePlayButton.clipsToBounds = true
        shufflePlayButton.layer.cornerRadius = 5.0
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
