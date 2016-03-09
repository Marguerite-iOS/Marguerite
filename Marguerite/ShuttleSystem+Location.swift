//
//  ShuttleSystem+Location.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

import MapKit

protocol ShuttleSystemLocationDelegate {
    func locationAvailable()
    func locationUnavailable()
}

extension ShuttleSystem: CoreLocationControllerDelegate {
    
    // MARK: - Shuttle system attributes
    
    /**
     Gets the Stanford Region
     - returns: The region.
     */
    var region: MKCoordinateRegion {
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.432233, longitude: -122.171183), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    }
    
    /**
     Creates a CGPath representing the Marguerite parking lot for inactive shuttles
     */
    func createParkingLotPath() {
        let coordinates: [(latitude: CGFloat, longitude: CGFloat)] = [(37.431005, -122.182307), (37.430743, -122.182835), (37.430777, -122.184055), (37.431262, -122.183943), (37.431646, -122.183562), (37.432474, -122.181883), (37.432613, -122.181046), (37.432555, -122.180617), (37.431584, -122.180435), (37.431462, -122.181274)]
        let mutablePath = CGPathCreateMutable()
        for (index, coordinate) in coordinates.enumerate() {
            if index == 0 {
                CGPathMoveToPoint(mutablePath, nil, coordinate.latitude, coordinate.longitude)
            } else {
                CGPathAddLineToPoint(mutablePath, nil, coordinate.latitude, coordinate.longitude)
            }
        }
        parkingLotPath = mutablePath
    }
    
    /**
     If shuttle coordinates in the main parking lot, then the shuttle is inactive
     */
    func coordinatesInParkingLot(latitude: Double, _ longitude: Double) -> Bool {
        return CGPathContainsPoint(parkingLotPath, nil, CGPointMake(CGFloat(latitude), CGFloat(longitude)), false)
    }
    
    // MARK: - CoreLocationControllerDelegate
    
    func locationAuthorizationStatusChanged(nowEnabled: Bool) {
        if nowEnabled {
            locationController.refreshLocation()
            locationDelegate?.locationAvailable()
        } else {
            locationDelegate?.locationUnavailable()
        }
    }
    
    func locationUpdate(location: CLLocation) {
        closestStops = getClosestStops(25, location: location)
        locationDelegate?.locationAvailable()
    }
    
    func locationError(error: NSError) {
        print("GPS location error: \(error.localizedDescription)")
        locationDelegate?.locationUnavailable()
    }
    
    // MARK: - Other
    
    /**
     Get a list of a certain number of closest stops to a location, or the
     number of stops, whichever is smaller. Calling this function also sets
     the "milesAway" variable for all of the stops returned.
     
     - parameter numStops: The number of closest stops to get.
     - parameter location: The location to find closest stops near.
     
     - returns: The list of closest stops to the provided location.
     */
    private func getClosestStops(numStops: Int, location: CLLocation) -> [ShuttleStop] {
        let allStops = Stop.getAllStops()
        
        let n = min(numStops, allStops.count)
        
        var stopsSortedByDistance: [ShuttleStop] = stops.sort { (first, second) -> Bool in
            first.distance = first.location?.distanceFromLocation(location)
            second.distance = second.location?.distanceFromLocation(location)
            return first.distance < second.distance
        }
        
        guard stopsSortedByDistance.count > 0 else {
            return []
        }
        
        return [ShuttleStop](stopsSortedByDistance[0...n-1])
    }
}