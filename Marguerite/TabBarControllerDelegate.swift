//
//  TabBarControllerDelegate.swift
//  Marguerite
//
//  Created by Andrew Finke on 7/19/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class TabBarControllerDelegate: NSObject, UITabBarControllerDelegate {
    
    private var lastSelectedTitle = ""
    private var lastSelectedCount = 0
    private var resetTimer: NSTimer?
    /**
    This method is for toggling between the map only mode and full mode
    */
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if let vcTitle = viewController.title {
            if lastSelectedTitle == vcTitle {
                lastSelectedCount++
            } else {
                lastSelectedTitle = vcTitle
                lastSelectedCount = 1
            }
            if lastSelectedCount > 10 {
                lastSelectedCount = 0
                (UIApplication.sharedApplication().delegate as! AppDelegate).toggleMapOnlyMode()
            }
        }
        resetTimer?.invalidate()
        resetTimer = NSTimer(timeInterval: 10.0, target: self, selector: "resetCount", userInfo: nil, repeats: false)
        return true
    }
    
    func resetCount() {
        lastSelectedCount = 0
    }
}
