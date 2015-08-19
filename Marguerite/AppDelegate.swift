//
//  AppDelegate.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright (c) 2015 Andrew Finke. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

/*
So this is a thing... The Marguerite department is in the middle of an upgrade. For the time being, this means none of the GTFS data is being updated. Until the upgrade is complete and the correct GTFS posted, the app will be in a live map only mode. The live map will continue to work as it is revered engineered off their website, though only with routes from the GTFS data updated in January.
*/
var liveMapModeOnly = true
let LiveMapModeOnlyKey = "Live Map Mode Only"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Fabric.with([Crashlytics()])

        setAppearances()
        FileHelper.ensureFolderExistance()
        if !DefaultsHelper.key(MovedGTFSBundleKey) {
            FileHelper.moveBundleToTempFolder()
            DefaultsHelper.keyIs(true, key: MovedGTFSBundleKey)
            DefaultsHelper.keyIs(true, key: LiveMapModeOnlyKey)
        }
        
        liveMapModeOnly = DefaultsHelper.key(LiveMapModeOnlyKey)
        
        // Only show the map view controller in the tab bar
        if liveMapModeOnly, let tabBarController = window?.rootViewController as? UITabBarController {
            tabBarController.viewControllers = [tabBarController.viewControllers![1]]
        }
    
        ShuttleSystem.sharedInstance.attemptStart()
        UIApplication.sharedApplication().statusBarHidden = false
        
        return true
    }
    
    /**
    Used to toggle between just the live map mode and all modes
    */
    func toggleMapOnlyMode() {
        DefaultsHelper.keyIs(true, key: NeedsDatabaseUpdateKey)
        liveMapModeOnly = !liveMapModeOnly
        DefaultsHelper.keyIs(liveMapModeOnly, key: LiveMapModeOnlyKey)
        let alertController = UIAlertController(title: "Full Release Mode: " + (!liveMapModeOnly).description.capitalizedString, message: "Toggled developer mode", preferredStyle: .Alert)
        let action = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            DefaultsHelper.keyIs(false, key: NeedsDatabaseUpdateKey)
            liveMapModeOnly = !liveMapModeOnly
            DefaultsHelper.keyIs(liveMapModeOnly, key: LiveMapModeOnlyKey)
        }
        alertController.addAction(action)
        window!.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
        Answers.logCustomEventWithName("Only Map Mode Toggled", customAttributes: ["Enabled": liveMapModeOnly.description.capitalizedString])
    }
    
    /**
    Sets the app's appearance properties
    */
    func setAppearances() {
        let shuttleSystemColor = ShuttleSystem.sharedInstance.color()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = shuttleSystemColor
        UITabBar.appearance().tintColor = UIColor.whiteColor()
        UITabBar.appearance().barTintColor = shuttleSystemColor
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

