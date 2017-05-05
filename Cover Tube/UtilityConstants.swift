//
//  UtilityConstants.swift
//  Cover Tube
//
//  Created by June Suh on 4/14/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation
import UIKit

let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height

// MARK: PlaylistViewController's constants
/* rectangular full youtube player view's size */
let rectangularFullYouTubePlayerViewSize = CGRect(x: 0.0, y: 0.0,
                                                  width: screenWidth, height: 233.0)

/* square full youtube player view's size */
let squareFullYouTubePlayerSize = CGSize(width: rectangularFullYouTubePlayerViewSize.height,
                                         height: rectangularFullYouTubePlayerViewSize.height)

/* square minimized youtube player view's size */
let squareMinimizedYouTubePlayerSize = CGSize(width: squareFullYouTubePlayerSize.width / 2.0,
                                              height: squareFullYouTubePlayerSize.height / 2.0)

/* corner radius of full square youtube player view's size to make it into a circle */
let fullYouTubePlayerCornerRadius = squareFullYouTubePlayerSize.height / 2.0

/* corner radius of minimized square youtube player view's size */
let minimizedYouTubePlayerCornerRadius = fullYouTubePlayerCornerRadius / 2.0

/* Full sized YouTube player view's top center point */
let fullSizeTopYouTubePlayerCenterPoint
    = CGPoint(x: screenWidth / 2.0,
              y: rectangularFullYouTubePlayerViewSize.height / 2.0)

/* Minimized YouTube player view's center point when in bottom center */
let minimizedSizeBottomCenterYouTubePlayerCenterPoint
    = CGPoint(x: screenWidth / 2.0,
              y: screenHeight - squareMinimizedYouTubePlayerSize.height / 2.0 + 5.0)

/* Minimized YouTube player view's frame.origin */
let minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint
    = CGPoint(x: screenWidth / 2.0 - squareMinimizedYouTubePlayerSize.width / 2.0,
              y : screenHeight - squareMinimizedYouTubePlayerSize.height + 10.0)

/* Size changing animation duration */
let changeSizeAnimationDuration = 3.0

/* This center point is used while minimizing the youtube animation in the center. */
let youtubePlayerViewAnimationCenterPointX : CGFloat
    = (rectangularFullYouTubePlayerViewSize.width - rectangularFullYouTubePlayerViewSize.height) / 2.0
