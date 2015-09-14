//
//  Shuttle.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import MapKit

struct ShuttleElement {
    static let name = "name"
    static let routeId = "routeid"
    static let tripId = "tripid"
    static let heading = "heading"
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let speed = "speed"
    static let time = "time"
}

class Shuttle: NSObject {
    
    // Neccesary
    var name: Int!
    var location: CLLocation!
    private var tripID: Int!
    private var routeID: Int!
    
    // Traveling route
    var route: ShuttleRoute!
    
    /**
    Initilizes a shuttle object from the live feed data dictionary.
    
    - parameter dictionary: The shuttle attributes.
    */
    init?(dictionary: [String:String]) {
        super.init()
        
        guard let dictionaryName = dictionary[ShuttleElement.name], dictionaryTripID = dictionary[ShuttleElement.tripId], dictionaryRouteID = dictionary[ShuttleElement.routeId], dictionaryLat = dictionary[ShuttleElement.latitude], dictionaryLong = dictionary[ShuttleElement.longitude] else {
            return nil
        }
        
        let latitude = (dictionaryLat as NSString).doubleValue
        let longitude = (dictionaryLong as NSString).doubleValue
        
        guard !ShuttleSystem.sharedInstance.coordinatesInParkingLot(latitude, longitude: longitude) else {
            return nil
        }
        
        name = Int(dictionaryName)
        tripID = Int(dictionaryTripID)
        routeID = Int(dictionaryRouteID)
        location = CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /**
    The annotation for the live map is the shuttle has a location.
    
    - returns: The annotation.
    */
    var annotation: ShuttleSystemAnnotation {
        return ShuttleSystemAnnotation(title: annotationTitle, object: self, type: .Shuttle, coordinate: location.coordinate)
    }
    
    var annotationTitle: String {
        return route.shortName + ": " + name.description
    }
    
    override var description: String {
        return route.shortName + ": " + name.description + ", Location: " + location.description
    }
    
}
