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

/* rectangular full youtube player overlay view's size. A little shorter than player view's height to distinguish user interaction between time slider and player */
let rectangularFullYouTubePlayerOverlayViewFrame
    = CGRect(origin: rectangularFullYouTubePlayerViewFrame.origin,
             size: CGSize(width: rectangularFullYouTubePlayerViewFrame.size.width,
                          height: rectangularFullYouTubePlayerViewFrame.size.height - 20.0))

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
              y: screenHeight - squareMinimizedYouTubePlayerSize.height / 2.0 - 20.0) // + 20.0)

/* Minimized YouTube player view's frame.origin */
let minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint
    = CGPoint(x: screenWidth / 2.0 - squareMinimizedYouTubePlayerSize.width / 2.0,
              y : screenHeight - squareMinimizedYouTubePlayerSize.height - 20.0) // + 40.0)

let minimizedSizeBottomCenterYouTubePlayerFrame
    = CGRect(origin: minimizedSizeBottomCenterYouTubePlayerFrameOriginPoint,
             size: squareMinimizedYouTubePlayerSize)


let minimizedYouTubePlayerViewTransformScale = CATransform3DScale(CATransform3DIdentity, 0.5, 0.5, 1.0)
let maximizedYouTubePlayerViewTransformScale = CATransform3DScale(CATransform3DIdentity, 1.0, 1.0, 1.0)

/* frame of linear time progress bar below youtube player view, indicating time. */
let linearTimeProgressBarFrame = CGRect(origin: CGPoint.zero,
                                        size: CGSize(width: screenWidth, height: 6.0))

/* circular progress bar frame size */
let circularProgressBarFrameSize = CGSize(width: squareMinimizedYouTubePlayerSize.width + 45.0,
                                          height: squareMinimizedYouTubePlayerSize.height + 45.0)

/* Size changing animation duration */
let changeSizeAnimationDuration = 0.75

/* This center point is used while minimizing the youtube animation in the center. */
let youtubePlayerViewAnimationCenterPointX : CGFloat
    = (rectangularFullYouTubePlayerViewFrame.width - rectangularFullYouTubePlayerViewFrame.height) / 2.0

// MARK: Animation Keys for YouTube Player View
let YouTubePlayerViewAnimation_TransformScale
    = "YouTubePlayerViewAnimation_TransformScale"

let YouTubePlayerViewAnimation_Position
    = "YouTubePlayerViewAnimation_Position"

let YouTubePlayerViewAnimation_CornerRadius
    = "YouTubePlayerViewAnimation_CornerRadius"


let YouTubePlayerViewAnimation_BoundsSizeWidth
    = "YouTubePlayerViewAnimation_BoundsSizeWidth"

let YouTubePlayerViewAnimation_BoundsSizeHeight
    = "YouTubePlayerViewAnimation_BoundsSizeHeight"

let YouTubePlayerViewAnimation_BoundsOriginX
    = "YouTubePlayerViewAnimation_BoundsOriginX"

let YouTubePlayerViewAnimation_BoundsOriginY
    = "YouTubePlayerViewAnimation_BoundsOriginY"

let MaximizeYouTubePlayerViewAnimation_TransformScale
    = "MaximizeYouTubePlayerViewAnimation_TransformScale"
let MaximizeYouTubePlayerViewAnimation_TopCenterPosition
    = "MaximizeYouTubePlayerViewAnimation_TopCenterPosition"

let MaximizeYouTubePlayerViewAnimation_SquareBoundsSizeWidth
    = "MaximizeYouTubePlayerViewAnimation_SquareBoundsSizeWidth"
let MaximizeYouTubePlayerViewAnimation_SquareBoundsSizeHeight
    = "MaximizeYouTubePlayerViewAnimation_SquareBoundsSizeHeight"
let MaximizeYouTubePlayerViewAnimation_BoundsOriginX
    = "MaximizeYouTubePlayerViewAnimation_BoundsOriginX"
let MaximizeYouTubePlayerViewAnimation_BoundsOriginY
    = "MaximizeYouTubePlayerViewAnimation_BoundsOriginY"

// MARK: Animation Keys for overlay view
let MinimizeYouTubePlayerOverlayViewAnimation_TransformScale
    = "MinimizeYouTubePlayerOverlayViewAnimation_TransformScale"
let MinimizeYouTubePlayerOverlayViewAnimation_BottomCenterPosition
    = "MinimizeYouTubePlayerOverlayViewAnimation_BottomCenterPosition"
let MinimizeYouTubePlayerOverlayViewAnimation_CornerRadius
    = "MinimizeYouTubePlayerOverlayViewAnimation_CornerRadius"
let MinimizeYouTubePlayerOverlayViewAnimation_SquareBoundsSizeWidth
    = "MinimizeYouTubePlayerOverlayViewAnimation_SquareBoundsSizeWidth"
let MinimizeYouTubePlayerOverlayViewAnimation_BoundsOriginX
    = "MinimizeYouTubePlayerOverlayViewAnimation_BoundsOriginX"


/* rotation speed */
let minimizedYouTubePlayerViewRotationSpeed : Float = 0.35


/* YouTube player view's size state */
enum YouTubePlayerViewSizeState {
    case minimized
    case fullScreen
    case hidden
}

/* YouTube player overlay view's gesture direction */
enum YouTubePlayerViewOverlayDirection {
    case down
    case up
}

/*  */
let lightGrayColor = UIColor(colorLiteralRed: 220.0/255, green: 220.0/255, blue: 220.0/255, alpha: 1)

/* color used for passed time in slider, CircularSpinner */
let minimumTrackColor = UIColor(colorLiteralRed: 47.0/255, green: 177.0/255, blue: 254.0/255, alpha: 1)

let maximumTrackColor = lightGrayColor
