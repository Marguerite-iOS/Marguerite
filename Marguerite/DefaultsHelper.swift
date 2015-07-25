//
//  DefaultsHelper.swift
//  Portfolio
//
//  Created by Andrew Finke on 1/23/15.
//  Copyright (c) 2015 ATFinke Productions. All rights reserved.
//

class DefaultsHelper: NSObject {
    
    static let appGroup = NSUserDefaults(suiteName: "group.edu.stanford.Marguerite")!
    
    /**
    Gets an NSUserDefaults NSData value and unarchives it
    
    :param: key The NSUserDefaults key
    
    :returns: The object
    */
    class func getObjectForKey(key : String) -> AnyObject? {
        let object: AnyObject? = appGroup.objectForKey(key)
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
        appGroup.setObject(object, forKey: key)
        appGroup.synchronize()
    }
    
    /**
    Gets an NSUserDefaults key bool value
    
    :param: key The NSUserDefaults key
    
    :returns: value The bool value
    */
    class func key(key : String) -> Bool {
        return appGroup.boolForKey(key)
    }
    
    /**
    Sets an NSUserDefaults key to a bool value
    
    :param: value The bool value
    :param: key The NSUserDefaults key
    */
    class func keyIs(value : Bool, key : String) {
        appGroup.setBool(value, forKey: key)
        appGroup.synchronize()
    }
}
