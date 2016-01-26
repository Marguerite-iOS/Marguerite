//
//  Constants.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

public enum DataKey: String {
    case NeedsDatabaseUpdate = "NeedsDatabaseUpdateKey"
    case NightMode = "NightModeKey"
    case FavoriteStopIDs = "FavoriteStopIDsKey"
}

public enum Notification: String {
    case FailedToUpdateShuttles = "FailedToUpdateShuttlesNotification"
    case UpdatingShuttles = "UpdatingShuttlesNotification"
    case UpdatedShuttles = "UpdatedShuttlesNotification"
    case UpdatedTheme = "UpdatedThemeNotification"
    case LocationAvailable = "LocationAvailableNotification"
    case LocationUnavailable = "LocationUnavailableNotification"
    case AddStopToFavorites = "AddStopToFavoritesNotification"
    case RemoveStopFromFavorites = "RemoveStopFromFavoritesNotification"
}
