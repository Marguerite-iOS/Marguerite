//
//  ShuttleSystemAnnotation.swift
//  StanfordBus
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
    
    var type: ShuttleSystemAnnotationType = .None
    // Used to store the system object, such as a ShuttleStop object
    var object: AnyObject?
    
    /**
    Initializes the annotation with necessary objects.
    
    :param: annotationTitle The title to be displayed.
    :param: annotationObject The object of the annotation.
    :param: annotationType The type of shuttle system object.
    :param: annotationCoordinate The coordniates of the annotation.
    */
    init(annotationTitle: String, annotationObject: AnyObject?, annotationType: ShuttleSystemAnnotationType,  annotationCoordinate: CLLocationCoordinate2D) {
        super.init()
        title = annotationTitle
        coordinate = annotationCoordinate
        object = annotationObject
        type = annotationType
    }
}
