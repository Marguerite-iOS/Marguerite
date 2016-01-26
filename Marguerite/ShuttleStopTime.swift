//
//  ShuttleStopTime.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/29/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

struct ShuttleStopTime {
    let route: ShuttleRoute!
    let tripID: String!
    
    let departureTime: NSDate!
    // Formatted departure time for display purposes
    let formattedTime: String!
    
    init(route: ShuttleRoute, tripID: String, departureTime: NSDate) {
        self.route = route
        self.tripID = tripID
        self.departureTime = departureTime
        formattedTime = ShuttleSystem.sharedInstance.displayFormatter.stringFromDate(departureTime)
    }
}
