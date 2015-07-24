//
//  DarkModeColors.swift
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
}
