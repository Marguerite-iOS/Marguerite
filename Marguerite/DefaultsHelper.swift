//
//  DefaultsHelper.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/23/15.
//  Copyright (c) 2015 ATFinke Productions. All rights reserved.
//

class DefaultsHelper: NSObject {
    
    static let appGroupDefaults = NSUserDefaults(suiteName: appGroupIdentifier)
    
    /**
    Gets an NSUserDefaults NSData value and unarchives it
    
    - parameter key: The NSUserDefaults key
    
    - returns: The object
    */
    class func getObjectForKey(key: String) -> AnyObject? {
        return appGroupDefaults?.objectForKey(key)
    }
    
    /**
    Saves an object as NSData to NSUserDefaults for specified key
    
    - parameter object: The bool value
    - parameter key: The NSUserDefaults key
    */
    class func saveDataForKey(object: AnyObject, key: String) {
        appGroupDefaults?.setObject(object, forKey: key)
        appGroupDefaults?.synchronize()
    }
    
    /**
    Gets an NSUserDefaults key bool value
    
    - parameter key: The NSUserDefaults key
    
    - returns: value The bool value
    */
    class func key(key: String) -> Bool {
        if let defaults = appGroupDefaults {
            return defaults.boolForKey(key)
        }
        return false
    }
    
    /**
    Sets an NSUserDefaults key to a bool value
    
    - parameter value: The bool value
    - parameter key: The NSUserDefaults key
    */
    class func keyIs(value: Bool, key: String) {
        appGroupDefaults?.setBool(value, forKey: key)
        appGroupDefaults?.synchronize()
    }
}
