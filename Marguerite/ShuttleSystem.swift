//
//  ShuttleSystem.swift
//  Marguerite
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

let FailedToUpdateShuttlesNotification = "FailedToUpdateShuttles"
let UpdatingShuttlesNotification = "UpdatingShuttles"
let UpdatedShuttlesNotification = "UpdatedShuttles"
let UpdatedThemeNotification = "UpdatesTheme"
let LocationAvailableNotification = "LocationAvailable"
let LocationUnavailableNotification = "LocationUnavailable"
let AddStopToFavoritesNotification = "AddStopToFavorites"
let RemoveStopFromFavoritesNotification = "RemoveStopFromFavorites"

class ShuttleSystem: NSObject, ShuttleGetterProtocol, CoreLocationControllerDelegate {
    
    static let sharedInstance = ShuttleSystem()
    
    private let realtimeShuttlesGetter = ShuttleGetter(urlString: MargueriteShuttlesLocationURL)
    private let locationController = CoreLocationController()
    private let distanceFormatter = MKDistanceFormatter()
    
    let fileHelper = FileHelper()
    
    var shuttles = [Shuttle]()
    var routes = [ShuttleRoute]()
    
    var stops = [ShuttleStop]()
    var closestStops = [ShuttleStop]()
    var favoriteStops = [ShuttleStop]()
    
    private var updatingShuttles = false
    private var didFailLastUpdate = false
    
    private var parkingLotPath: CGPath!
    
    private var favoriteStopIDs: [Int]!
    
    private var updateTimer: NSTimer?
    
    var nightModeEnabled = false {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(UpdatedThemeNotification, object: nil)
            DefaultsHelper.keyIs(nightModeEnabled, key: NightModeKey)
            Answers.logCustomEventWithName("3.0: Night Mode Toggled", customAttributes: ["Enabled": nightModeEnabled.description.capitalizedString])
        }
    }
    
    var viewingLiveMap = false {
        didSet {
            toggleShuttleUpdating()
        }
    }
    
    
    // The formatter for displaying departure time to the user
    var displayFormatter: NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter
                }()
        }
        return Static.instance
    }
    
    // The formatter for reading date from database
    var databaseDateFormatter: NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
                }()
        }
        return Static.instance
    }
    
    // The formatter for reading time from database
    var databaseTimeFormatter: NSDateFormatter {
        struct Static {
            static let instance: NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                return formatter
                }()
        }
        return Static.instance
    }
    
    func databaseQueryStringsFromDate(date: NSDate) -> (dateString: String, timeString: String) {
        return (databaseDateFormatter.stringFromDate(date), databaseTimeFormatter.stringFromDate(date))
    }
    
    override init() {
        super.init()
        realtimeShuttlesGetter.delegate = self
        locationController.delegate = self
        nightModeEnabled = DefaultsHelper.key(NightModeKey)
        createParkingLotPath()
    }
    
    func start() {
        if fileHelper.hasCompletedInitalSetup {
            print("Device has GTFS")
            loadData()
        } else {
            print("Device has no GTFS")
        }
    }
    
    // MARK: - Loading the data
    
    /**
    Starts the loading data process
    */
    private func loadData() {
        print("*** Loading Shuttle System ***")
        shuttles = []
        stops = []
        routes = []
        closestStops = []
        
        if DefaultsHelper.key(NeedsDatabaseUpdateKey) {
            print("--- Updating Database ---")
            let importer = CSVImporter()
            importer.addAgency()
            importer.addRoute()
            importer.addStop()
            importer.addCalendarDate()
            importer.addTrip()
            importer.addStopTime()
            importer.addStopRoutes()
            importer.vacuum()
            importer.reindex()
            print("--- Finished Updating Database ---")
            DefaultsHelper.keyIs(false, key: NeedsDatabaseUpdateKey)
        }
        
        print("Loading ShuttleRoute Objects")
        
        Route.getAllRoutes().forEach({
            if let dictionary = $0 as? [String:AnyObject], newRoute = ShuttleRoute(dictionary: dictionary) {
                routes.append(newRoute)
            }
        })
        
        print("Loading ShuttleStop Objects")
        
        Stop.getAllStops().forEach({
            if let dictionary = $0 as? [String:AnyObject], newStop = ShuttleStop(dictionary: dictionary) {
                stops.append(newStop)
            }
        })
        
        stops.sortInPlace( {$0.name < $1.name} )
        locationController.refreshLocation()
        realtimeShuttlesGetter.update()
        loadFavorites()
        
        ShuttleSystem.sharedInstance.fileHelper.getLatestGTFSData()
        
        print("*** Finished Loading Shuttle System ***")
    }
    
    // MARK: - Realtime buses protocol
    
    func toggleShuttleUpdating() {
        updateRealtimeLocations()
    }
    
    func didUpdateShuttles(shuttlesInfo: [[String: String]], mappingInfo: [String: String]) {
        didFailLastUpdate = false
        shuttles = []
        shuttlesInfo.forEach({
            if let shuttleName = $0["name"], mapping = mappingInfo[shuttleName] {
                if let route = shuttleRouteWithID(mapping) {
                    if let shuttle = Shuttle(dictionary: $0, route: route) {
                        shuttles.append(shuttle)
                    }
                } else {
                    print(shuttleName + ": bad route: " + mapping)
                    Answers.logCustomEventWithName("3.0: Bad Shuttle Route", customAttributes: ["Shuttle:RouteMapping": shuttleName + ":" + mapping])
                }
            }
        })
        dispatch_async(dispatch_get_main_queue(),{
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            NSNotificationCenter.defaultCenter().postNotificationName(UpdatedShuttlesNotification, object: nil)
            self.updateTimer = NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: "updateRealtimeLocations", userInfo: nil, repeats: false)
        })
        updatingShuttles = false
        Answers.logCustomEventWithName("3.0: Live Map Updated", customAttributes: [:])
    }
    
    func busUpdateDidFail(error: ShuttleGetterError) {
        var message = ""
        
        if error.wasConnectingToServer() {
            message = NSLocalizedString("Server Connect Error Message", comment: "")
        } else {
            message = NSLocalizedString("Data Validation Error Message", comment: "")
        }
        
        Answers.logCustomEventWithName("3.0: Live Map Error", customAttributes: ["Code":error.hashValue.description])
        
        updatingShuttles = false
        
        if !didFailLastUpdate {
            didFailLastUpdate = true
            updateRealtimeLocations()
            return
        }
        Answers.logCustomEventWithName("3.0: Displayed Live Map Error", customAttributes: [:])
        dispatch_async(dispatch_get_main_queue(),{
            NSNotificationCenter.defaultCenter().postNotificationName(FailedToUpdateShuttlesNotification, object: message)
        })
    }
    
    func updateRealtimeLocations() {
        if !updatingShuttles && viewingLiveMap {
            dispatch_async(dispatch_get_main_queue(),{
                self.updatingShuttles = true
                self.updateTimer?.invalidate()
                self.realtimeShuttlesGetter.update()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                NSNotificationCenter.defaultCenter().postNotificationName(UpdatingShuttlesNotification, object: nil)
            })
        }
    }
    
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
    private func createParkingLotPath() {
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
    
    // MARK: - Favorite stops
    
    private func loadFavorites() {
        favoriteStops = []
        if let favs = DefaultsHelper.getObjectForKey(FavoriteStopsIDKey) as? [Int] {
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
        DefaultsHelper.saveDataForKey(favoriteStopIDs, key: FavoriteStopsIDKey)
    }
    
    /**
    Removes a shuttle stop from the favorites.
    
    - parameter stop: The shuttle stop.
    */
    func removeStopFromFavorites(stop: ShuttleStop) {
        if let index = favoriteStopIDs.indexOf(stop.stopID) {
            favoriteStops.removeAtIndex(index)
            favoriteStopIDs.removeAtIndex(index)
            DefaultsHelper.saveDataForKey(favoriteStopIDs, key: FavoriteStopsIDKey)
        }
    }
    
    /**
    Detects if a stop has been favorited
    
    - parameter stop: The shuttle stop.
    
    - returns: The Bool value.
    */
    func isStopFavorited(stop: ShuttleStop) -> Bool {
        return favoriteStopIDs.indexOf(stop.stopID) != nil
    }
    
    // MARK: - CoreLocationControllerDelegate
    
    func locationAuthorizationStatusChanged(nowEnabled: Bool) {
        if nowEnabled {
            locationController.refreshLocation()
        }
        let notificationName = nowEnabled ? LocationAvailableNotification : LocationUnavailableNotification
        dispatch_async(dispatch_get_main_queue(),{
            NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: nil)
        })
    }
    
    func locationUpdate(location: CLLocation) {
        closestStops = getClosestStops(25, location: location)
        dispatch_async(dispatch_get_main_queue(),{
            NSNotificationCenter.defaultCenter().postNotificationName(LocationAvailableNotification, object: nil)
        })
    }
    
    func locationError(error: NSError) {
        print("GPS location error: \(error.localizedDescription)")
        dispatch_async(dispatch_get_main_queue(),{
            NSNotificationCenter.defaultCenter().postNotificationName(LocationUnavailableNotification, object: nil)
        })
        
    }
    
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
        
        return [ShuttleStop](stopsSortedByDistance[0...n-1])
    }
}
