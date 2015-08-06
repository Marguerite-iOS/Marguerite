//
//  DefaultsHelper.swift
//  Portfolio
//
//  Created by Andrew Finke on 1/23/15.
//  Copyright (c) 2015 ATFinke Productions. All rights reserved.
//

class DefaultsHelper: NSObject {
    
    static let appGroupDefaults = NSUserDefaults(suiteName: appGroupIdentifier)!
    
    /**
    Gets an NSUserDefaults NSData value and unarchives it
    
    :param: key The NSUserDefaults key
    
    :returns: The object
    */
    class func getObjectForKey(key : String) -> AnyObject? {
        let object: AnyObject? = appGroupDefaults.objectForKey(key)
        if object != nil {
            return object
        }
        return nil
    }
    
    /**
    Saves an object as NSData to NSUserDefaults for specified key
    
    :param: object The bool value
    :param: key The NSUserDefaults key
    */
    class func saveDataForKey(object : AnyObject, key : String) {
        appGroupDefaults.setObject(object, forKey: key)
        appGroupDefaults.synchronize()
    }
    
    /**
    Gets an NSUserDefaults key bool value
    
    :param: key The NSUserDefaults key
    
    :returns: value The bool value
    */
    class func key(key : String) -> Bool {
        return appGroupDefaults.boolForKey(key)
    }
    
    /**
    Sets an NSUserDefaults key to a bool value
    
    :param: value The bool value
    :param: key The NSUserDefaults key
    */
    class func keyIs(value : Bool, key : String) {
        appGroupDefaults.setBool(value, forKey: key)
        appGroupDefaults.synchronize()
    }
}
