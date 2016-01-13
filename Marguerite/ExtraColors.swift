//
//  ExtraColors.swift
//  Marguerite
//
//  Created by Andrew Finke on 7/19/15.
//  Copyright (c) 2015 Andrew Finke. All rights reserved.
//

import Foundation

extension UIColor {
    class func darkModeCellColor() -> UIColor {
        return UIColor(red: 31.0/255.0, green: 35.0/255.0, blue: 44.0/255.0, alpha: 1.0)
    }
    class func darkModeSeperatorColor() -> UIColor {
        return UIColor(red: 49.0/255.0, green: 53.0/255.0, blue: 64.0/255.0, alpha: 1.0)
    }
    class func darkModeTableViewColor() -> UIColor {
        return UIColor(red: 27.0/255.0, green: 31.0/255.0, blue: 40.0/255.0, alpha: 1.0)
    }
    class func darkModeCellSelectionColor() -> UIColor {
        return UIColor(red: 51.0/255.0, green: 56.0/255.0, blue: 62.0/255.0, alpha: 1.0)
    }
    class func cellSelectionColor() -> UIColor {
        return UIColor(red: 216.75/255.0, green: 216.75/255.0, blue: 216.75/255.0, alpha: 1.0)
    }
    class func cellDetailTextColor() -> UIColor {
        return UIColor(red: 142.0/255.0, green: 142.0/255.0, blue: 147.0/255.0, alpha: 1.0)
    }
    class func cardinalColor() -> UIColor {
        return UIColor(red: 141.0/255.0, green: 22.0/255.0, blue: 22.0/255.0, alpha: 1.0)
    }
    
    /**
     Gets the routes UIColor from a hex value. Thanks to http://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios.
     
     - parameter The: hex string.
     */
    class func fromHexString(hex: String) -> UIColor {
        var cString = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if cString.hasPrefix("#") {
            cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
        }
        
        if cString.characters.count != 6 {
            return UIColor.grayColor()
        }
        
        var rgbValue: UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
