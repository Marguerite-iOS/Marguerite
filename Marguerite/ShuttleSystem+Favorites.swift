//
//  ShuttleSystem+Favorites.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

extension ShuttleSystem {
    // MARK: - Favorite stops
    
    func loadFavorites() {
        favoriteStops = []
        if let favs = DefaultsHelper.getObjectForKey(DataKey.FavoriteStopIDs.rawValue) as? [Int] {
            favoriteStopIDs = favs
            favoriteStopIDs.forEach({
                if let stop = shuttleStopWithID($0.description) {
                    favoriteStops.append(stop)
                }
            })
            favoriteStops.sortInPlace({$0.name < $1.name})
        } else {
            favoriteStopIDs = []
        }
    }
    
    /**
     Adds a shuttle stop to the favorites.
     
     - parameter stop: The shuttle stop.
     */
    func addStopToFavorites(stop: ShuttleStop) {
        favoriteStops.append(stop)
        favoriteStopIDs.append(stop.stopID)
        DefaultsHelper.saveDataForKey(favoriteStopIDs, key: DataKey.FavoriteStopIDs.rawValue)
    }
    
    /**
     Removes a shuttle stop from the favorites.
     
     - parameter stop: The shuttle stop.
     */
    func removeStopFromFavorites(stop: ShuttleStop) {
        if let index = favoriteStopIDs.indexOf(stop.stopID) {
            favoriteStops.removeAtIndex(index)
            favoriteStopIDs.removeAtIndex(index)
            DefaultsHelper.saveDataForKey(favoriteStopIDs, key: DataKey.FavoriteStopIDs.rawValue)
        }
    }
    
    /**
     Detects if a stop has been favorited
     
     - parameter stop: The shuttle stop.
     
     - returns: The Bool value.
     */
    func isStopFavorited(stop: ShuttleStop) -> Bool {
        return favoriteStopIDs.contains(stop.stopID)
    }
}
