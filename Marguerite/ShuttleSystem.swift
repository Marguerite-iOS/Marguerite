//
//  ShuttleSystem.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import MapKit
import Crashlytics

let NeedsDatabaseUpdateKey = "Needs Database Update"
let NightModeKey = "Night Mode"
let FavoriteStopsIDKey = "Favorite Stop IDs"

let UpdatedShuttlesNotification = "UpdatesShuttles"
let UpdatedThemeNotification = "UpdatesTheme"
let LocationAvailableNotification = "LocationAvailable"
let LocationUnavailableNotification = "LocationUnavailable"

class ShuttleSystem: NSObject, RealtimeShuttlesGetterProtocol, CoreLocationControllerDelegate {
    
    static let sharedInstance = ShuttleSystem()
    
    private let realtimeShuttlesGetter = RealtimeShuttlesGetter(urlString: MargueriteShuttlesLocationURL)
    private let locationController = CoreLocationController()
    private let distanceFormatter = MKDistanceFormatter()
    
    let fileHelper = FileHelper()

    var shuttles: [Shuttle]!
    var routes: [ShuttleRoute]!
    
    var stops: [ShuttleStop]!
    var closestStops: [ShuttleStop]!
    var favoriteStops: [ShuttleStop]!
    private var favoriteStopIDs: [Int]!
    
    private var updateTimer: NSTimer?
    
    var nightModeEnabled = false {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(UpdatedThemeNotification, object: nil)
            DefaultsHelper.keyIs(nightModeEnabled, key: NightModeKey)
            Answers.logCustomEventWithName("Night Mode Toggled", customAttributes: ["Enabled": nightModeEnabled.description.capitalizedString])
        }
    }
    
    
    // The formatter for displaying departure time to the user
    var formatter: NSDateFormatter {
        struct Static {
            static let instance : NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter
                }()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        realtimeShuttlesGetter.delegate = self
        locationController.delegate = self
        nightModeEnabled = DefaultsHelper.key(NightModeKey)
    }
    
    func attemptStart() {
        if fileHelper.hasCompletedInitalSetup {
            println("Device has GTFS")
            loadData()
        } else {
            println("Device has no GTFS")
        }
    }
    
    // MARK: - Loading the data
    
    /**
    Starts the loading data process
    */
    private func loadData() {
        let startShuttleSystemLoad = NSDate()
        println("*** Loading Shuttle System ***")
        shuttles = []
        stops = []
        routes = []
        closestStops = []
        
        if DefaultsHelper.key(NeedsDatabaseUpdateKey) {
            println("--- Updating Database ---")
            let importer = CSVImporter()
            importer.addAgency()
            importer.addRoute()
            importer.addStop()
            if !liveMapModeOnly {
                importer.addCalendarDate()
                importer.addTrip()
                importer.addStopTime()
                importer.addStopRoutes()
            }
            importer.vacuum()
            importer.reindex()
            println("--- Finished Updating Database ---")
            DefaultsHelper.keyIs(false, key: NeedsDatabaseUpdateKey)
        }
        
        println("Loading ShuttleRoute Objects")
        Route.getAllRoutes().map({self.routes.append(ShuttleRoute(dictionary: $0 as! [String : AnyObject]))})
        println("Loading ShuttleStop Objects")
        Stop.getAllStops().map({self.stops.append(ShuttleStop(dictionary: $0 as! [String : AnyObject]))})
        
        if !liveMapModeOnly {
            println("--- Loading Stops Into Routes ---")
            routes.map({$0.loadStops})
            println("--- Finished Loading Stops Into Routes ---")
        }
        
        stops.sort({$0.name < $1.name})
        locationController.refreshLocation()
        realtimeShuttlesGetter.update()
        loadFavorites()
        
        if !liveMapModeOnly {
            ShuttleSystem.sharedInstance.fileHelper.getLatestGTFSData()
        }
        
        println("*** Finished Loading Shuttle System ***")
    }
    
    // MARK: - Realtime buses protocol
    
    func didUpdateShuttles(shuttlesInfo: [[String : String]], mappingInfo: [String : String]) {
        var shuttleNamesWithErrors = [String]()
        shuttles = []
        for shuttle in shuttlesInfo {
            if let shuttleName = shuttle["name"] {
                if let mapping = mappingInfo[shuttleName] {
                    let shuttle = Shuttle(dictionary: shuttle)
                    if let route = shuttleRouteWithID(mapping) {
                        shuttle.route = route
                        shuttles.append(shuttle)
                    } else {
                        println(shuttleName + ": bad route: " + mapping)
                        shuttleNamesWithErrors.append(shuttleName)
                        Answers.logCustomEventWithName("Bad Shuttle Route", customAttributes: ["Shuttle": shuttleName, "RouteMapping": mapping])
                    }
                } else {
                    shuttleNamesWithErrors.append(shuttleName)
                }
            }
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        NSNotificationCenter.defaultCenter().postNotificationName(UpdatedShuttlesNotification, object: nil)
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "updateRealtimeLocations", userInfo: nil, repeats: false)
    }
    
    func busUpdateDidFail(error: NSError) {
        var message = ""
        
        switch error.code {
        case 1:
            message = NSLocalizedString("Server Connect Error Message", comment: "")
        case 2:
            message = NSLocalizedString("Data Validation Error Message", comment: "")
            Answers.logCustomEventWithName("Data Validation Error", customAttributes: [:])
        default:
            break
        }
        
        CLSLogv("Live buses error: %@", getVaList([message]))
        
        let alertController = UIAlertController(title: NSLocalizedString("Updating Shuttles Error Title", comment: ""), message: message + NSLocalizedString("Try Again Error Message End", comment: ""), preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Dismiss Button", comment: ""), style: .Cancel, handler: nil))
        
        let action = UIAlertAction(title: NSLocalizedString("Try Again Button", comment: ""), style: .Default) { (action) in
            self.updateRealtimeLocations()
        }
        alertController.addAction(action)
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if let rootViewController = appDelegate.window?.rootViewController {
                rootViewController.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func updateRealtimeLocations() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        realtimeShuttlesGetter.update()
    }
    
    // MARK: - Shuttle system attributes
    
    /**
    Gets the Stanford Region
    
    :returns: The region.
    */
    var region: MKCoordinateRegion {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.432233, longitude: -122.171183), span: span)
    }
    
    /**
    Gets the Stanford cardinal color
    
    :returns: The color.
    */
    func color() -> UIColor {
        return UIColor(red: 141.0/255.0, green: 22.0/255.0, blue: 22.0/255.0, alpha: 1.0)
    }
    
    // MARK: - Matching items with string
    
    /**
    Gets the shuttle route with name.
    
    :param: name The route name.
    
    :returns: The route if it exists.
    */
    func shuttleRouteWithName(name: String) -> ShuttleRoute? {
        return routes.filter{ $0.shortName == name }.first
    }
    
    /**
    Gets the shuttle route with ID.
    
    :param: routeID The route ID.
    
    :returns: The route if it exists.
    */
    func shuttleRouteWithID(routeID: String) -> ShuttleRoute? {
        let routeIDVal = routeID.toInt()
        return routes.filter{ $0.routeID == routeIDVal }.first
    }
    
    /**
    Gets the shuttle stop with name.
    
    :param: name The stop name.
    
    :returns: The stop if it exists.
    */
    func shuttleStopWithID(stopID: String) -> ShuttleStop? {
        let stopIDVal = stopID.toInt()
        return stops.filter{ $0.stopID == stopIDVal }.first
    }
    
    // MARK: - Favorite stops
    
    private func loadFavorites() {
        favoriteStops = []
        if let favs = DefaultsHelper.getObjectForKey(FavoriteStopsIDKey) as? [Int] {
            favoriteStopIDs = favs
            for stopID in favoriteStopIDs {
                if let stop = shuttleStopWithID(stopID.description) {
                    favoriteStops.append(stop)
                }
            }
            favoriteStops.sort({$0.name < $1.name})
        } else {
            favoriteStopIDs = []
        }
    }
    
    /**
    Adds a shuttle stop to the favorites.
    
    :param: stop The shuttle stop.
    */
    func addStopToFavorites(stop: ShuttleStop) {
        favoriteStops.append(stop)
        favoriteStopIDs.append(stop.stopID)
        DefaultsHelper.saveDataForKey(favoriteStopIDs, key: FavoriteStopsIDKey)
        Answers.logCustomEventWithName("Add Stop To Favorites", customAttributes: ["StopID": stop, "StopName": stop.name])
    }
    
    /**
    Removes a shuttle stop from the favorites.
    
    :param: stop The shuttle stop.
    */
    func removeStopFromFavorites(stop: ShuttleStop) {
        if let index = find(favoriteStopIDs, stop.stopID) {
            favoriteStops.removeAtIndex(index)
            favoriteStopIDs.removeAtIndex(index)
            DefaultsHelper.saveDataForKey(favoriteStopIDs, key: FavoriteStopsIDKey)
            Answers.logCustomEventWithName("Remove Stop From Favorites", customAttributes: ["StopID": stop, "StopName": stop.name])
        }
    }
    
    /**
    Detects if a stop has been favorited
    
    :param: stop The shuttle stop.
    
    :returns: The Bool value.
    */
    func isStopFavorited(stop: ShuttleStop) -> Bool {
        return find(favoriteStopIDs, stop.stopID) != nil
    }
    
    // MARK: - CoreLocationControllerDelegate
    
    func locationAuthorizationStatusChanged(nowEnabled: Bool) {
        if nowEnabled {
            locationController.refreshLocation()
        }
        let notificationName = nowEnabled ? LocationAvailableNotification : LocationUnavailableNotification
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: nil)
        Answers.logCustomEventWithName("Location Status Updated", customAttributes: ["Enabled": nowEnabled.description.capitalizedString])
    }
    
    func locationUpdate(location: CLLocation) {
        closestStops = getClosestStops(25, location: location)
        NSNotificationCenter.defaultCenter().postNotificationName(LocationAvailableNotification, object: nil)
    }
    
    func locationError(error: NSError) {
        println("GPS location error: \(error.localizedDescription)")
        NSNotificationCenter.defaultCenter().postNotificationName(LocationUnavailableNotification, object: nil)
    }
    
    /**
    Get a list of a certain number of closest stops to a location, or the
    number of stops, whichever is smaller. Calling this function also sets
    the "milesAway" variable for all of the stops returned.
    
    :param: numStops The number of closest stops to get.
    :param: location The location to find closest stops near.
    
    :returns: The list of closest stops to the provided location.
    */
    private func getClosestStops(numStops: Int, location: CLLocation) -> [ShuttleStop] {
        
        let allStops = Stop.getAllStops()
        
        let n = min(numStops, allStops.count)
        
        var stopsSortedByDistance: [ShuttleStop] = stops.sorted { (first, second) -> Bool in
            first.distance = first.location?.distanceFromLocation(location)
            second.distance = second.location?.distanceFromLocation(location)
            return first.distance < second.distance
        }
        
        return [ShuttleStop](stopsSortedByDistance[0...n-1])
    }
}