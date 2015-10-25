//
//  ShuttleStopTime.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/29/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class ShuttleStopTime: NSObject {
    var route: ShuttleRoute!
    var tripID: String!
    
    var departureTime: NSDate!
    // Formatted departure time for display purposes
    var formattedTime: String!
    
    init(route: ShuttleRoute, tripID: String, departureTime: NSDate) {
        super.init()
        self.route = route
        self.tripID = tripID
        self.departureTime = departureTime
        formattedTime = ShuttleSystem.sharedInstance.displayFormatter.stringFromDate(departureTime)
    }
}
