//
//  ShuttleSystemAnnotation.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/17/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import MapKit

class ShuttleSystemAnnotation: MKPointAnnotation {
    
    /**
   Type of shuttle system object
    
    - Shuttle: A live shuttle annotation
    - Stop: A stopo annotation
    */
    enum ShuttleSystemAnnotationType {
        case Shuttle
        case Stop
        case None
    }
    
    lazy var type: ShuttleSystemAnnotationType = .None
    // Used to store the system object, such as a ShuttleStop object
    var object: AnyObject?
    var hasUpdatedLocation = false
    
    /**
    Initializes the annotation with necessary objects.
    
    - parameter annotationTitle: The title to be displayed.
    - parameter annotationObject: The object of the annotation.
    - parameter annotationType: The type of shuttle system object.
    - parameter annotationCoordinate: The coordniates of the annotation.
    */
    init(title: String, object: AnyObject?, type: ShuttleSystemAnnotationType, coordinate: CLLocationCoordinate2D) {
        super.init()
        self.title = title
        self.coordinate = coordinate
        self.object = object
        self.type = type
    }
}
