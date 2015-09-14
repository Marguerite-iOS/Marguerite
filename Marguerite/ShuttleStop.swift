//
//  ShuttleStop.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import MapKit

class ShuttleStop: NSObject {
    
    var name: String!
    var stopID: Int!
    
    var location: CLLocation!
    // Distance from user
    var distance: Double?
    // Upcoming stop times
    var stopTimes: [ShuttleStopTime]!
    // Routes the stop here
    private var routes: [ShuttleRoute]!
    // Route string for database purposes
    private var routesString = ""
    // Image of all the routes the stop here
    var routeBubblesImage: UIImage?
    
    // MARK: - Loading Data
    
    /**
    Initilizes a shuttle stop object from the GTFS data formatted into a dictionary.
    
    - parameter dictionary: The shuttle stop attributes.
    */
    init?(dictionary: [String:AnyObject]?) {
        super.init()
        
        guard let dictionary = dictionary, dictionaryStopName = dictionary["stop_name"] as? String, dictionaryStopID = dictionary["stop_id"] as? String, dictionaryLat = (dictionary["stop_lat"] as? NSNumber)?.doubleValue, dictionaryLon = (dictionary["stop_lon"] as? NSNumber)?.doubleValue else {
            return nil
        }
        
        name = dictionaryStopName
        stopID = Int(dictionaryStopID)
        location = CLLocation(latitude: dictionaryLat, longitude: dictionaryLon)
        
        if !liveMapModeOnly {
            createRoutes(dictionary)
            stopTimes = getShuttleStopTimes()
            routeBubblesImage = getRouteBubblesImage()
        }
    }
    
    /**
    Gets all the routes the stop here based on the GTFS data and sorts them first by length then by name.
    
    - parameter dictionary: The routes infomation.
    */
    private func createRoutes(dictionary: [String:AnyObject]) {
        routes = []
        if let dicRoutes = dictionary["routes"] as? String {
            for (index, dicRouteName) in dicRoutes.componentsSeparatedByString(",").enumerate()  {
                if let route = ShuttleSystem.sharedInstance.shuttleRouteWithName(dicRouteName) {
                    routes.append(route)
                    if index != 0 {
                        routesString += ","
                    }
                    routesString += route.routeID.description
                }
            }
            // sort for alphabetical
            routes = routes.sort({$0.shortName < $1.shortName})
            // then sort for shorter names
            routes = routes.sort({
                (rt1: ShuttleRoute, rt2: ShuttleRoute) -> Bool in
                return rt1.shortName.characters.count < rt2.shortName.characters.count
            })
        }
    }
    
    /**
    Gets the upcoming stop times using the database.
    
    - returns: The next stop times.
    */
    private func getShuttleStopTimes() -> [ShuttleStopTime] {
        if let db = FMDatabase.databaseWithPath(Util.getDatabasePath()) as? FMDatabase {
            if !db.open() { return []  }
            let currentDate = NSDate()
            
            let (todaysDate, timeString) = ShuttleSystem.sharedInstance.databaseQueryStringsFromDate(currentDate)
            
            if let _ = stopID {
                let departureTimesQuery = String(format: "SELECT stop_times.departure_time, routes.route_long_name, routes.route_short_name, routes.route_color, routes.route_text_color, trips.trip_id FROM routes, trips, calendar_dates, stop_times WHERE trips.service_id=calendar_dates.service_id AND calendar_dates.date=?  AND stop_times.trip_id=trips.trip_id AND routes.route_id=trips.route_id  AND stop_times.stop_id=? AND trips.route_id IN (%@) AND time(stop_times.departure_time) > time(\'%@\') GROUP BY stop_times.departure_time, routes.route_long_name ORDER BY time(stop_times.departure_time)", arguments: [routesString, timeString])
                
                let departureTimesRS = db.executeQuery(departureTimesQuery, withArgumentsInArray: [todaysDate, stopID])
                
                var shuttleStopTimes = [ShuttleStopTime]()
                while departureTimesRS.next() {
                    if let routeName = departureTimesRS.objectForColumnName("route_short_name") as? String, route = ShuttleSystem.sharedInstance.shuttleRouteWithName(routeName), tripID = departureTimesRS.objectForColumnName("trip_id") as? String, var departureTimeString = departureTimesRS.objectForColumnName("departure_time") as? String {
                        var timeTokens = departureTimeString.componentsSeparatedByString(":")
                        if timeTokens[0] == "24" {
                            timeTokens[0] = "00"
                            departureTimeString = timeTokens.joinWithSeparator(":")
                        }
                        if let departureTimeDate = ShuttleSystem.sharedInstance.databaseTimeFormatter.dateFromString(departureTimeString) {
                            let stopTime = ShuttleStopTime(route: route, tripID: tripID, departureTime: departureTimeDate)
                            shuttleStopTimes.append(stopTime)
                        }
                    }
                }
                departureTimesRS.close()
                db.close()
                return shuttleStopTimes
            }
            
        }
        return []
    }
    
    // MARK: - UI
    
    /**
    The annotation for the live map.
    
    - returns: The annotation.
    */
    var annotation: ShuttleSystemAnnotation {
        return ShuttleSystemAnnotation(title: name, object: self, type: .Stop, coordinate: location.coordinate)
    }
    
    // MARK: - Route Bubbles
    
    /**
    Gets the image of all the routes the stop here and saves it for later use.
    
    - returns: The image.
    */
    private func getRouteBubblesImage() -> UIImage? {
        var images: [UIImage] = []
        routes.forEach({images.append($0.image)})
        if images.count == 0 {
            return nil
        }
        
        let finalImageWidth =  UIScreen.mainScreen().bounds.width
        let finalImageHeight = expectedHeightForImages(images, finalWidth: finalImageWidth)
        
        let size = CGSizeMake(finalImageWidth, finalImageHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        var currentWidth =  CGFloat(0.0)
        var currentHeight = CGFloat(0.0)
        for image in images {
            if currentWidth + image.size.width + 10.0 < finalImageWidth {
                image.drawAtPoint(CGPointMake(currentWidth, currentHeight))
                currentWidth += image.size.width + 10.0
            } else {
                currentWidth = 0.0
                currentHeight += image.size.height + 10.0
                image.drawAtPoint(CGPointMake(currentWidth, currentHeight))
            }
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /**
    Gets the expected height of the image with all the routes.
    
    - parameter images: The image.
    - parameter finalWidth: The width of the image.
    
    - returns: The height.
    */
    private func expectedHeightForImages(images: [UIImage], finalWidth: CGFloat) -> CGFloat {
        var width = CGFloat(0.0)
        var height = CGFloat(images[0].size.height)
        for image in images {
            if width + image.size.width + 10.0 < finalWidth {
                width += image.size.width + 10.0
            } else {
                width = 0.0
                height += image.size.height + 10.0
            }
        }
        return height
    }
}
