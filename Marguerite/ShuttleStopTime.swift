//
//  ShuttleStopTime.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/29/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class ShuttleStopTime: NSObject {
    var departureTime: NSDate?
    var route: ShuttleRoute?
    var tripId: String?
    // Formatted departure time for display purposes
    var formattedTime: String?
}
