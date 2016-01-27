//
//  ShuttleSystem.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

class ShuttleSystem: NSObject {
    
    static let sharedInstance = ShuttleSystem()
    
    var locationDelegate: ShuttleSystemLocationDelegate?
    var liveShuttlesDelegate: ShuttleSystemLiveShuttlesDelegate?
    
    let fileHelper = FileHelper()
    let locationController = CoreLocationController()
    let realtimeShuttlesGetter = ShuttleGetter(urlString: MargueriteShuttlesLocationURL)
    
    var shuttles = [Shuttle]()
    var routes = [ShuttleRoute]()
    
    var stops = [ShuttleStop]()
    var closestStops = [ShuttleStop]()
    var favoriteStops = [ShuttleStop]()
    
    var parkingLotPath: CGPath!
    var favoriteStopIDs: [Int]!
    
    var updatingShuttles = false
    var didFailLastUpdate = false
    var updateTimer: NSTimer?
    
    var nightModeEnabled = false {
        didSet {
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.UpdatedTheme.rawValue, object: nil)
            DefaultsHelper.keyIs(nightModeEnabled, key: DataKey.NightMode.rawValue)
        }
    }
    
    var viewingLiveMap = false {
        didSet {
            toggleShuttleUpdating()
        }
    }
    
    override init() {
        super.init()
        realtimeShuttlesGetter.delegate = self
        locationController.delegate = self
        nightModeEnabled = DefaultsHelper.key(DataKey.NightMode.rawValue)
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
        
        if DefaultsHelper.key(DataKey.NeedsDatabaseUpdate.rawValue) {
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
            DefaultsHelper.keyIs(false, key: DataKey.NeedsDatabaseUpdate.rawValue)
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
}
