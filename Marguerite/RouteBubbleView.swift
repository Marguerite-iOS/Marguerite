//
//  RouteBubbleView.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/30/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class RouteBubbleView: UIView {
    
    private var route: ShuttleRoute!
    
    /**
    Creates a logo as a UIView for a shuttle route to be displayed thoughout the app.
    
    - parameter route: The shuttle route to create a UIView for.
    */
    init(route: ShuttleRoute) {
        super.init(frame: CGRectZero)
        self.route = route
        let label = UILabel(frame: CGRectZero)
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        label.textColor = route.routeTextColor
        label.text = " " + route.shortName.uppercaseString + " "
        label.sizeToFit()
        addSubview(label)
        frame = label.frame
        backgroundColor = route.routeColor
        layer.cornerRadius = 10.25
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK - Class functions

    /**
    Creates a logo image for a shuttle route to be displayed thoughout the app.
    
    - parameter route: The shuttle route to save the image of.
    */
    class func saveBubbleForRoute(route: ShuttleRoute) -> UIImage {
        let bubble = RouteBubbleView(route: route)
        UIGraphicsBeginImageContextWithOptions(bubble.bounds.size, false, 0.0)
        let _ = UIGraphicsGetCurrentContext()
        bubble.drawViewHierarchyInRect(bubble.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}