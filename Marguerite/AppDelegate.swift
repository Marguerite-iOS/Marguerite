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

enum ShortcutIdentifier: String {
    case OpenStops
    case OpenLiveMap
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics()])

        checkIntegrity()
        ShuttleSystem.sharedInstance.start()
        
        loadAppearances()
        loadInterface()
        
        return true
    }
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        guard let shortcutIdentifier = ShortcutIdentifier(rawValue: shortcutItem.type) else {
            return completionHandler(false)
        }
        (window!.rootViewController as! UITabBarController).selectedIndex = shortcutIdentifier == ShortcutIdentifier.OpenStops ? 0 : 1
        return completionHandler(true)
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
        if let rootViewController = window?.rootViewController {
            rootViewController.presentViewController(alertController, animated: true, completion: nil)
            Answers.logCustomEventWithName("Only Map Mode Toggled", customAttributes: ["Enabled": liveMapModeOnly.description.capitalizedString])
        }
    }
    
    /**
    Sets the app's appearance properties
    */
    func loadAppearances() {
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = UIColor.cardinalColor()
        UITabBar.appearance().tintColor = UIColor.whiteColor()
        UITabBar.appearance().barTintColor = UIColor.cardinalColor()
    }
    
    func loadInterface() {
        let tabBarController = window!.rootViewController as! UITabBarController
        let splitViewController = tabBarController.viewControllers![0] as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.preferredDisplayMode = .AllVisible
        splitViewController.preferredPrimaryColumnWidthFraction = 0.5
        splitViewController.delegate = self
        
        // Only show the map view controller in the tab bar
        if liveMapModeOnly {
            tabBarController.viewControllers = [tabBarController.viewControllers![1]]
        }
        else {
            let stops = UIApplicationShortcutItem(type: ShortcutIdentifier.OpenStops.rawValue, localizedTitle: "Show Stops", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "BusEmpty")
                , userInfo: nil)
            let map = UIApplicationShortcutItem(type: ShortcutIdentifier.OpenLiveMap.rawValue, localizedTitle: "Show Live Map", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "MapEmpty")
                , userInfo: nil)
            UIApplication.sharedApplication().shortcutItems = [stops, map]
        }
        UIApplication.sharedApplication().statusBarHidden = false
    }
    
    func checkIntegrity() {
        FileHelper.ensureFolderExistance()
        if !DefaultsHelper.key(MovedGTFSBundleKey) {
            FileHelper.moveBundleToTempFolder()
            DefaultsHelper.keyIs(true, key: MovedGTFSBundleKey)
            DefaultsHelper.keyIs(true, key: LiveMapModeOnlyKey)
        }
        liveMapModeOnly = DefaultsHelper.key(LiveMapModeOnlyKey)
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
    
    // MARK: - Split view
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? StopInfoTableViewController else { return false }
        if topAsDetailController.stop == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
}

