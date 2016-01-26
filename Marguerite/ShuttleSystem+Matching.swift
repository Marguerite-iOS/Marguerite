//
//  ShuttleSystem+Matching.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

import Foundation

extension ShuttleSystem {
    // MARK: - Matching items with string
    
    /**
    Gets the shuttle route with name.
    
    - parameter name: The route name.
    
    - returns: The route if it exists.
    */
    func shuttleRouteWithName(name: String) -> ShuttleRoute? {
        return routes.filter { $0.shortName == name }.first
    }
    
    /**
     Gets the shuttle route with ID.
     
     - parameter routeID: The route ID.
     
     - returns: The route if it exists.
     */
    func shuttleRouteWithID(routeID: String) -> ShuttleRoute? {
        let routeIDVal = Int(routeID)
        return routes.filter { $0.routeID == routeIDVal }.first
    }
    
    /**
     Gets the shuttle stop with name.
     
     - parameter name: The stop name.
     
     - returns: The stop if it exists.
     */
    func shuttleStopWithID(stopID: String) -> ShuttleStop? {
        let stopIDVal = Int(stopID)
        return stops.filter { $0.stopID == stopIDVal }.first
    }
    
    /**
     Gets the stop at index path based on the selected segemented control index
     
     - parameter indexPath: The index path
     
     - returns: The stop
     */
    func stopForIndexPath(indexPath: NSIndexPath, scope: Int) -> ShuttleStop {
        switch scope {
        case 1:
            return favoriteStops[indexPath.row]
        case 2:
            return closestStops[indexPath.row]
        default:
            return stops[indexPath.row]
        }
    }
}
