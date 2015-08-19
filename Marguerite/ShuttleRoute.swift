//
//  ShuttleRoute.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class ShuttleRoute: NSObject {
    
    // Necessary
    var routeID: Int!
    var shortName: String!
    var routeColor: UIColor!
    var routeTextColor: UIColor!
    var image: UIImage!
    var routeURL: NSURL!
    
    // All the stops on the route
    private var stops: [ShuttleStop] = []
    private var longName: String?
    
    // MARK: - Loading Data
    /**
    Initilizes a shuttle route object from the GTFS data formatted into a dictionary.
    
    :param: dictionary The shuttle route attributes.
    */
    init?(dictionary: [String:AnyObject]?) {
        super.init()
        if let dictionaryRouteID = (dictionary?["route_id"] as? String)?.toInt(), dictionaryShortName = dictionary?["route_short_name"] as? String, dictionaryRouteURLString = dictionary?["route_url"] as? String, dictionaryRouteURL = NSURL(string: dictionaryRouteURLString), dictionaryRouteColor =  dictionary?["route_color"] as? String, dictionaryRouteTextColor =  dictionary?["route_text_color"] as? String {
            routeID = dictionaryRouteID
            shortName = dictionaryShortName
            routeURL = dictionaryRouteURL
            
            routeColor = hexStringToUIColor(dictionaryRouteColor)
            routeTextColor = hexStringToUIColor(dictionaryRouteTextColor)
        }
        else {
            return nil
        }
        
        if let dictionaryLongName = dictionary?["route_long_name"] as? String where count(dictionaryLongName) > 3 {
            longName = dictionaryLongName
            if longName == "Va Tram" {
                shortName = "VA"
            }
        }
        
        image = RouteBubbleView.saveBubbleForRoute(self)
    }
    
    var displayName: String {
        if let longName = longName {
            return longName
        }
        return shortName
    }

    
    /**
    Gets the routes UIColor from a hex value. Thanks to http://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios.
    
    :param: The hex string.
    */
    private func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(advance(cString.startIndex, 1))
        }
        
        if (count(cString) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
    /**
    Begins the process of fetching all stops on the route
    */
    func loadStops() {
        if let db = FMDatabase.databaseWithPath(Util.getDatabasePath()) as? FMDatabase {
            if !db.open() {}
            let currentDate = NSDate()
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todaysDate = dateFormatter.stringFromDate(currentDate)
            dateFormatter.dateFormat = "HH:mm:ss"
            let timeString = dateFormatter.stringFromDate(currentDate)
            
            
            if let routeID = routeID {
                let queryString = String(format: "SELECT DISTINCT stops.stop_id FROM trips INNER JOIN stop_times ON stop_times.trip_id = trips.trip_id INNER JOIN stops ON stops.stop_id = stop_times.stop_id WHERE route_id = %@", arguments: [routeID.description])
                
                let query = db.executeQuery(queryString, withArgumentsInArray: [])
                
                let calendar = NSCalendar.currentCalendar()
                while query.next() {
                    if let stopID = query.objectForColumnName("stop_id") as? String {
                        if let stop = ShuttleSystem.sharedInstance.shuttleStopWithID(stopID) {
                            stops.append(stop)
                        }
                    }
                }
                query.close()
                db.close()
            }
        }
    }
}

