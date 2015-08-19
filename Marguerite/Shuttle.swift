//
//  Shuttle.swift
//  StanfordBus
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
    
    // Optional
    private var speed: Double?
    private var heading: Double?
    
    // Traveling route
    var route: ShuttleRoute!
    
    /**
    Initilizes a shuttle object from the live feed data dictionary.
    
    :param: dictionary The shuttle attributes.
    */
    init?(dictionary: [String:String]) {
        super.init()
        if let dictionaryName = dictionary[ShuttleElement.name]?.toInt(), dictionaryTripID = dictionary[ShuttleElement.tripId]?.toInt(), dictionaryRouteID = dictionary[ShuttleElement.routeId]?.toInt(), dictionaryLat = dictionary[ShuttleElement.latitude], dictionaryLong = dictionary[ShuttleElement.longitude] {
            name = dictionaryName
            tripID = dictionaryTripID
            routeID = dictionaryRouteID
            let lat = (dictionaryLat as NSString).doubleValue
            let long = (dictionaryLong as NSString).doubleValue
            location = CLLocation(latitude: lat, longitude: long)
        }
        else {
            return nil
        }
        
        if let dictionarysSpeed = dictionary[ShuttleElement.speed] {
            speed = (dictionarysSpeed as NSString).doubleValue
        }
        if let dictionaryHeading = dictionary[ShuttleElement.heading] {
            heading = (dictionaryHeading as NSString).doubleValue
        }
    }
    
    /**
    The annotation for the live map is the shuttle has a location.
    
    :returns: The annotation.
    */
    var annotation: ShuttleSystemAnnotation {
        return ShuttleSystemAnnotation(annotationTitle: annotationTitle, annotationObject: self, annotationType: .Shuttle, annotationCoordinate: location.coordinate)
    }
    
    var annotationTitle: String {
        return route.shortName + ": " + name.description
    }
    
}
