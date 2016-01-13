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

struct Shuttle {
    
    // Neccesary
    let name: Int!
    let location: CLLocation!
    
    // Traveling route
    let route: ShuttleRoute!
    
    /**
    Initilizes a shuttle object from the live feed data dictionary.
    
    - parameter dictionary: The shuttle attributes.
    - parameter route: The shuttle route.
    */
    init?(dictionary: [String:String], route: ShuttleRoute) {
        
        guard let dictionaryName = dictionary[ShuttleElement.name], dictionaryLat = dictionary[ShuttleElement.latitude], dictionaryLong = dictionary[ShuttleElement.longitude], latitude =  Double(dictionaryLat), longitude =  Double(dictionaryLong) else {
            return nil
        }
        
        guard !ShuttleSystem.sharedInstance.coordinatesInParkingLot(latitude, longitude) else {
            return nil
        }
        
        name = Int(dictionaryName)
        location = CLLocation(latitude: latitude, longitude: longitude)
        self.route = route
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
}
