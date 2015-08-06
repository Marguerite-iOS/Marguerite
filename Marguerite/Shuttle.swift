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
    private var tripID: Int!
    private var routeID: Int!
    
    // Optional
    var location: CLLocation?
    private var time: Double?
    private var speed: Double?
    private var heading: Double?
    
    // Traveling route
    var route: ShuttleRoute!
    
    /**
    Initilizes a shuttle object from the live feed data dictionary.
    
    :param: dictionary The shuttle attributes.
    */
    init(dictionary: [String:String]) {
        super.init()
        name = dictionary[ShuttleElement.name]!.toInt()
        tripID = dictionary[ShuttleElement.tripId]!.toInt()
        routeID = dictionary[ShuttleElement.routeId]!.toInt()
        
        if let timeString = dictionary[ShuttleElement.time] {
            time = (timeString as NSString).doubleValue
        }
        if let speedString = dictionary[ShuttleElement.speed] {
            speed = (speedString as NSString).doubleValue
        }
        if let headingString = dictionary[ShuttleElement.heading] {
            heading = (headingString as NSString).doubleValue
        }
        if let latString = dictionary[ShuttleElement.latitude], longString = dictionary[ShuttleElement.longitude] {
            let lat = (latString as NSString).doubleValue
            let long = (longString as NSString).doubleValue
            location = CLLocation(latitude: lat, longitude: long)
        }
    }
    
    /**
    The annotation for the live map is the shuttle has a location.
    
    :returns: The annotation.
    */
    var annotation: ShuttleSystemAnnotation? {
        if let coordinate = location?.coordinate {
            return ShuttleSystemAnnotation(annotationTitle: annotationTitle, annotationObject: self, annotationType: .Shuttle, annotationCoordinate: coordinate)
        }
        return nil
    }
    
    var annotationTitle: String {
        return route.shortName + ": " + name.description
    }
    
}
