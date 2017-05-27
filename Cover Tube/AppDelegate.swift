//
//  AppDelegate.swift
//  Cover Tube
//
//  Created by June Suh on 3/2/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit
import SnapchatSwipeContainer


/* setup swipe view controllers */
let storyboard = UIStoryboard(name: "Main", bundle: nil)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /* Two main view controllers for this app
     NOTE: swipeContainerVC contains three view controllers. */
    private var swipeContainerVC : SwipeContainerViewController? = nil
    
    /* return app delegate */
    class func getAppDelegate () -> AppDelegate?
    {
        if let appDelegate = UIApplication.shared.delegate {
            return UIApplication.shared.delegate as! AppDelegate
        } else {
            return nil
        }
    }
    
    /* return Snapchat swipe container view controller */
    class func getSnapchatSwipeContainerVC () -> SwipeContainerViewController? {
        if let appDelegate = getAppDelegate() {
            return appDelegate.swipeContainerVC
        } else {
            return nil
        }
    }
    
    /* set Snapchat swipe container view controller */
    class func setSnapchatSwipeContainerVC () {
        if let appDelegate = getAppDelegate() {
            appDelegate.swipeContainerVC = storyboard.instantiateViewController(withIdentifier: "SwipeContainerVC") as? SwipeContainerViewController
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // getAuthState()
        // isAuthTokenActive()
        AppDelegate.setSnapchatSwipeContainerVC()
        logout()
        // updateRootViewController()
        window?.rootViewController = AppDelegate.getSnapchatSwipeContainerVC()
        // updateRootViewController()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if (currentAuthorizationFlow != nil) {
            if currentAuthorizationFlow!.resumeAuthorizationFlow(with: url) {
                currentAuthorizationFlow = nil
                return true
            }
        }
        
        return false
    }

}

