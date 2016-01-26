//
//  ShuttleRoute.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

struct ShuttleRoute {
    
    // Necessary
    let routeID: Int!
    var shortName: String!
    let routeColor: UIColor!
    let routeTextColor: UIColor!
    var image: UIImage!
    let routeURL: NSURL!
    
    // All the stops on the route
    //private var stops: [ShuttleStop] = []
    private var longName: String?
    
    // MARK: - Loading Data
    /**
    Initilizes a shuttle route object from the GTFS data formatted into a dictionary.
    
    - parameter dictionary: The shuttle route attributes.
    */
    init?(dictionary: [String:AnyObject]?) {
        
        guard let dictionary = dictionary, dictionaryRouteID = dictionary["route_id"] as? String, dictionaryShortName = dictionary["route_short_name"] as? String, dictionaryRouteURLString = dictionary["route_url"] as? String, dictionaryRouteURL = NSURL(string: dictionaryRouteURLString), dictionaryRouteColor =  dictionary["route_color"] as? String, dictionaryRouteTextColor =  dictionary["route_text_color"] as? String else {
            return nil
        }
        
        routeID = Int(dictionaryRouteID)
        shortName = dictionaryShortName
        routeURL = dictionaryRouteURL
        
        routeColor = UIColor.fromHexString(dictionaryRouteColor)
        routeTextColor = UIColor.fromHexString(dictionaryRouteTextColor)
        
        if let dictionaryLongName = dictionary["route_long_name"] as? String where dictionaryLongName.characters.count > 3 {
            longName = dictionaryLongName
            if longName == "Va Tram" {
                shortName = "VA"
            } else if longName == "Mc Holiday" {
                shortName = "MCH"
                longName = "MC Holiday"
            }
        }
        image = RouteBubbleView.bubbleForRoute(self)
    }
    
    var displayName: String {
        if let longName = longName {
            return longName
        }
        return shortName
    }
}
