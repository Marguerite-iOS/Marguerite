//
//  ShuttleSystem+LiveShuttles.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

import Crashlytics

extension ShuttleSystem: ShuttleGetterProtocol {
    // MARK: - Realtime buses protocol
    
    func toggleShuttleUpdating() {
        updateRealtimeLocations()
    }
    
    func didUpdateShuttles(shuttlesInfo: [[String: String]], mappingInfo: [String: String]) {
        didFailLastUpdate = false
        shuttles = []
        shuttlesInfo.forEach({
            if let shuttleName = $0["name"], mapping = mappingInfo[shuttleName] {
                if let route = shuttleRouteWithID(mapping) {
                    if let shuttle = Shuttle(dictionary: $0, route: route) {
                        shuttles.append(shuttle)
                    }
                } else {
                    print(shuttleName + ": bad route: " + mapping)
                    Answers.logCustomEventWithName("3.0: Bad Shuttle Route", customAttributes: ["Shuttle:RouteMapping": shuttleName + ":" + mapping])
                }
            }
        })
        dispatch_async(dispatch_get_main_queue(),{
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.UpdatedShuttles.rawValue, object: nil)
            self.updateTimer = NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: "updateRealtimeLocations", userInfo: nil, repeats: false)
        })
        updatingShuttles = false
        Answers.logCustomEventWithName("3.0: Live Map Updated", customAttributes: [:])
    }
    
    func busUpdateDidFail(error: ShuttleGetterError) {
        var message = ""
        
        if error.wasConnectingToServer() {
            message = NSLocalizedString("Server Connect Error Message", comment: "")
        } else {
            message = NSLocalizedString("Data Validation Error Message", comment: "")
        }
        
        Answers.logCustomEventWithName("3.0: Live Map Error", customAttributes: ["Code":error.hashValue.description])
        
        updatingShuttles = false
        
        if !didFailLastUpdate {
            didFailLastUpdate = true
            updateRealtimeLocations()
            return
        }
        Answers.logCustomEventWithName("3.0: Displayed Live Map Error", customAttributes: [:])
        dispatch_async(dispatch_get_main_queue(),{
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.FailedToUpdateShuttles.rawValue, object: message)
        })
    }
    
    func updateRealtimeLocations() {
        if !updatingShuttles && viewingLiveMap {
            dispatch_async(dispatch_get_main_queue(),{
                self.updatingShuttles = true
                self.updateTimer?.invalidate()
                self.realtimeShuttlesGetter.update()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.UpdatingShuttles.rawValue, object: nil)
            })
        }
    }
}
