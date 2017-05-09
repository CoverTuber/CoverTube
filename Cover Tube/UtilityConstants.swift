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
let rectangularFullYouTubePlayerViewFrame = CGRect(x: 0.0, y: 0.0,
                                                  width: screenWidth, height: 233.0)

/* square full youtube player view's size */
let squareFullYouTubePlayerSize = CGSize(width: rectangularFullYouTubePlayerViewFrame.size.height,
                                         height: rectangularFullYouTubePlayerViewFrame.size.height)

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
              y: rectangularFullYouTubePlayerViewFrame.height / 2.0)

/* Minimized YouTube player view's center point when in bottom center */
let minimizedSizeBottomCenterYouTubePlayerCenterPoint
    = CGPoint(x: screenWidth / 2.0,
              y: screenHeight - squareMinimizedYouTubePlayerSize.height / 2.0 + 20.0)

/* Minimized YouTube player view's frame.origin */
let minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint
    = CGPoint(x: screenWidth / 2.0 - squareMinimizedYouTubePlayerSize.width / 2.0,
              y : screenHeight - squareMinimizedYouTubePlayerSize.height + 40.0)

/* circular progress bar frame size */
let circularProgressBarFrameSize = CGSize(width: squareMinimizedYouTubePlayerSize.width + 45.0,
                                          height: squareMinimizedYouTubePlayerSize.height + 45.0)

/* Size changing animation duration */
let changeSizeAnimationDuration = 3.0

/* This center point is used while minimizing the youtube animation in the center. */
let youtubePlayerViewAnimationCenterPointX : CGFloat
    = (rectangularFullYouTubePlayerViewFrame.width - rectangularFullYouTubePlayerViewFrame.height) / 2.0

/* Animation keys */
// MARK: Minimizing YouTube Player View strings used as keys
let MinimizeYouTubePlayerViewAnimation_TransformScale = "MinimizeYouTubePlayerViewAnimation_TransformScale"
let MinimizeYouTubePlayerViewAnimation_BottomCenterPosition = "MinimizeYouTubePlayerViewAnimation_BottomCenterPosition"
let MinimizeYouTubePlayerViewAnimation_CornerRadius = "MinimizeYouTubePlayerViewAnimation_CornerRadius"
let MinimizeYouTubePlayerViewAnimation_SquareBoundsSizeWidth = "MinimizeYouTubePlayerViewAnimation_SquareBoundsSizeWidth"
let MinimizeYouTubePlayerViewAnimation_BoundsOriginX = "MinimizeYouTubePlayerViewAnimation_BoundsOriginX"


let MinimizeYouTubePlayerViewAnimationStrings
    = [MinimizeYouTubePlayerViewAnimation_TransformScale,
       MinimizeYouTubePlayerViewAnimation_BoundsOriginX,
       MinimizeYouTubePlayerViewAnimation_CornerRadius,
       MinimizeYouTubePlayerViewAnimation_SquareBoundsSizeWidth,
       MinimizeYouTubePlayerViewAnimation_BoundsOriginX ]

/* rotation speed */
let minimizedYouTubePlayerViewRotationSpeed : Float = 0.35


/* YouTube player view's size state */
enum YouTubePlayerViewSizeState {
    case minimized
    case fullScreen
    case hidden
}
