//
//  MapTableViewCell.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import MapKit

class MapTableViewCell: UITableViewCell, MKMapViewDelegate {

    /*
    Displays a map view in a table view cell
    */
    
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.showsUserLocation = true
            mapView.delegate = self
        }
    }
    
    /**
    Adds the stop annotiation to the map.
    
    - parameter stop: The stop to display
    */
    func displayStop(stop: ShuttleStop) {
        mapView.showAnnotations([stop.annotation], animated: false)
    }
    
    // MARK: - Map view delegate
    
    // delegate method for rendering the shuttles and stops
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Stop")
        pinView.pinColor = .Red
        pinView.canShowCallout = false
        return pinView
    }
}
