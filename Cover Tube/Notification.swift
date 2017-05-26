//
//  Notification.swift
//  Cover Tube
//
//  Created by June Suh on 5/10/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//  This file

import Foundation
import UIKit
import SwiftMessages

/*
 Displays thin line at top of the screen temporary notification
 */
func showStatusLineNotification (title : String,
                                 bodyText : String,
                                 duration : TimeInterval,
                                 backgroundColor : UIColor,
                                 foregroundColor : UIColor)
{
    showNotification(layout: MessageView.Layout.StatusLine, title: title, bodyText: bodyText, iconStyle: IconStyle.default, theme: Theme.info, dropShadow: false, showButton: false, showIcon: false, showTitle: false, showBody: true, presentationStyle: SwiftMessages.PresentationStyle.top , presentationContext: .window(windowLevel: UIWindowLevelStatusBar), duration: .seconds(seconds: duration) , dimMode: SwiftMessages.DimMode.none, shouldAutoRotate: true, interactiveHide: false, backgroundColor: backgroundColor, foregroundColor: foregroundColor)
}

/* show error */
func showStatusLineErrorNotification (title : String,
                                 bodyText : String,
                                 duration : TimeInterval)
{
    showStatusLineNotification (title : title,
                                bodyText : bodyText,
                                duration : duration,
                                backgroundColor : UIColor.red,
                                foregroundColor : UIColor.white)
}


/*
 Designated method for showing a notification
 */
private func showNotification(layout : MessageView.Layout,
                              title : String,
                              bodyText : String,
                              iconStyle : IconStyle,
                              theme : Theme,
                              dropShadow : Bool,
                              showButton : Bool,
                              showIcon : Bool,
                              showTitle : Bool,
                              showBody : Bool,
                              presentationStyle : SwiftMessages.PresentationStyle ,
                              presentationContext : SwiftMessages.PresentationContext,
                              duration : SwiftMessages.Duration,
                              dimMode : SwiftMessages.DimMode,
                              shouldAutoRotate : Bool,
                              interactiveHide : Bool,
                              backgroundColor : UIColor,
                              foregroundColor : UIColor)
{
    // View setup
    let view = MessageView.viewFromNib(layout: layout)
    
    view.configureContent(title: title, body: bodyText,
                          iconImage: nil, iconText: nil,
                          buttonImage: nil, buttonTitle: "Hide",
                          buttonTapHandler: { _ in SwiftMessages.hide() })
    
    
    view.configureTheme(theme, iconStyle: iconStyle)
    
    if dropShadow {
        view.configureDropShadow()
    }
    
    if !showButton {
        view.button?.isHidden = true
    }
    
    if !showIcon {
        view.iconImageView?.isHidden = true
        view.iconLabel?.isHidden = true
    }
    
    if !showTitle {
        view.titleLabel?.isHidden = true
    }
    
    if !showBody {
        view.bodyLabel?.isHidden = true
    }
    
    // Config setup
    
    var config = SwiftMessages.defaultConfig
    
    config.presentationStyle = presentationStyle
    
    config.presentationContext = presentationContext
    
    config.duration = duration
    
    config.dimMode = dimMode
    
    config.shouldAutorotate = shouldAutoRotate
    
    config.interactiveHide = interactiveHide
    
    // Set status bar style unless using card view (since it doesn't
    // go behind the status bar).
    if case .top = config.presentationStyle, layout != .CardView {
        if theme != .info {
            config.preferredStatusBarStyle = .lightContent
        }
    }
    
    view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
    
    // Show
    SwiftMessages.show(config: config, view: view)
}
