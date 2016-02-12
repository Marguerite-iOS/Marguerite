//
//  ShuttleGetter.swift
//  A convenience class for getting information about real-time locations of
//  Marguerite shuttle buses.
//
//  A lot of the details of this implementation were reverse-engineered from
//  the Marguerite web-based live shuttle map (javascript):
//  http://lbre-apps.stanford.edu/transportation/stanford_ivl/
//
//  Created by Kevin Conley on 3/8/15.
//  Copyright (c) 2015 Kevin Conley & Andrew Finke. All rights reserved.
//

import UIKit
import CoreLocation
import Crashlytics

enum ShuttleGetterError {
    case URLFormattingError, ParserGuardError, ParserStartParseError, ParserParseError, ParserDataError, ParserJSONError
    func wasConnectingToServer() -> Bool {
        return self == .URLFormattingError || self == .ParserGuardError || self == .ParserStartParseError
    }
}

protocol ShuttleGetterProtocol {
    func didUpdateShuttles(shuttlesInfo: [[String: String]], mappingInfo: [String: String])
    func busUpdateDidFail(error: ShuttleGetterError)
}

class ShuttleGetter: NSObject, NSXMLParserDelegate {
    
    // MARK: - Public API
    
    private var urlString: String
    var delegate: ShuttleGetterProtocol?
    
    /**
    Refresh the buses by downloading the XML feed, asynchronously.
    */
    func update() {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: NSURL(string: "http://lbre-apps.stanford.edu/transportation/stanford_ivl/locations.cfm")!)) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let data = data, xml = String(data: data, encoding: NSUTF8StringEncoding) {
                self.parseXML(xml)
            }
        }
        task.resume()
        
        guard let url = NSURL(string: urlString) else {
            delegate?.busUpdateDidFail(.URLFormattingError)
            return
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) { () -> Void in
            guard let parser = NSXMLParser(contentsOfURL: url) else {
                self.delegate?.busUpdateDidFail(.ParserGuardError)
                return
            }
            parser.delegate = self
            if !parser.parse() {
                self.delegate?.busUpdateDidFail(.ParserStartParseError)
            }
        }
    }
    
    // MARK: - Initializer
    
    init(urlString: String) {
        self.urlString = urlString
    }
    
    private var vehicleDictionaries = [[String: String]]()

    func parseXML(xml: String) {
        vehicleDictionaries = []
        let xml = SWXMLHash.parse(xml)
        do {
            let vehicles = try xml.byKey("vehicle-locations").byKey("vehicle")
            for vehicles in vehicles {
                do {
                    var vehicleDictionary = [String: String]()
                    vehicleDictionary[ShuttleElement.name] = try vehicles.byKey(ShuttleElement.name).element?.text
                    vehicleDictionary[ShuttleElement.routeId] = try vehicles.byKey(ShuttleElement.routeId).element?.text
                    vehicleDictionary[ShuttleElement.latitude] = try vehicles.byKey(ShuttleElement.latitude).element?.text
                    vehicleDictionary[ShuttleElement.longitude] = try vehicles.byKey(ShuttleElement.longitude).element?.text
                    vehicleDictionaries.append(vehicleDictionary)
                } catch {
                }
            }
        } catch {
            self.delegate?.busUpdateDidFail(.ParserDataError)
            return
        }
        compiledVehicleDictionaries()
    }
    
    func compiledVehicleDictionaries() {
        // Construct vehicle ID string for POST request
        let vehicleIdString = extractVehicleIdsFromBusDictionaries(vehicleDictionaries)
        
        // Perform POST request
        
        guard let url = NSURL(string: MargueriteShuttleLookupURL) else {
            return
        }
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        let postString = "name=\(vehicleIdString)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard error == nil, let data = data else {
                self.delegate?.busUpdateDidFail(.ParserDataError)
                return
            }
            guard let jsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject], unwrappedJSONdata = jsonData, mappings = unwrappedJSONdata["DATA"] as? [[AnyObject]] else {
                self.delegate?.busUpdateDidFail(.ParserJSONError)
                return
            }
            var vehicleIdsToFareboxIds = [String:String]()
            for mapping  in mappings as [[AnyObject]] {
                // Each input bus id returns as an array of objects with the bus id and farebox id of the bus's route
                if mapping.count == 2 {
                    vehicleIdsToFareboxIds[String(format: "%@", mapping[0].description)] = self.getRouteIdWithFareboxId(String(format: "%@", mapping[1].description))
                }
            }
            self.delegate?.didUpdateShuttles(self.vehicleDictionaries, mappingInfo: vehicleIdsToFareboxIds)
        })
        task.resume()
    }
    
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        var attributes = ["Known":parseError.userInfo.description]
        if let unknownError = parser.parserError {
            attributes["Unknown"] = unknownError.userInfo.description
        }
        Answers.logCustomEventWithName("3.0: Parser Failed", customAttributes: attributes)
        delegate?.busUpdateDidFail(.ParserParseError)
    }
    
    /**
    Create a string of comma-separated vehicleIds from a list of bus XML dictionaries.
    
    - parameter busDictionaries: The list of bus dictionaries constructed from XML.
    
    - returns: The comma-separated string of vehicleIds.
    */
    private func extractVehicleIdsFromBusDictionaries(busDictionaries: [[String:String]]) -> String {
        var vehicleIds = [String]()
        
        for busDictionary in busDictionaries {
            if let vehicleId = busDictionary[ShuttleElement.name] {
                // this is a hack for SMP, following the web-based live map
                if busDictionary[ShuttleElement.routeId] == "8888" {
                    vehicleIds.append("8888")
                } else {
                    vehicleIds.append(vehicleId)
                }
            }
        }
        
        return vehicleIds.joinWithSeparator(",")
    }
    
    /**
    The XML feed identifies buses using a numeric ID in the name
    element, called a vehicle ID.
    
    The vehicle ID is translated to a farebox ID using the POST request in
    "parserDidEndDocument()".
    
    This function translates a farebox ID into the corresponding GTFS route ID.
    
    - parameter fareboxId: The fareboxId to translate to a GTFS route ID.
    
    - returns: The resulting GTFS route ID, or nil upon failure.
    */
    func getRouteIdWithFareboxId(fareboxId: String) -> String? {
        if let fareboxIdInt = Int(fareboxId) {
            switch fareboxIdInt {
            case 8888:
                //Stanford Menlo Park
                return "40"
            case 9999:
                //Bohannon
                return "53"
            case 2:
                //Line Y (Clockwise)
                return "2"
            case 3:
                //Line X (Counter-Clockwise)
                return "3"
            case 4:
                //Line C
                return "4"
            case 5:
                //Tech
                return "54"
            case 8:
                //SLAC
                return "8"
            case 9:
                //Line N
                return "9"
            case 10:
                //Line O
                return "43"
            case 11:
                //Shopping Express
                return "18"
            case 15:
                //Line V
                return "61"
            case 17:
                //Line P
                return "20"
            case 19:
                //Medical Center
                return "22"
            case 23:
                //1050 Arastradero
                return "28"
            case 28:
                //Line S
                return "33"
            case 29:
                //Ardenwood Express
                return "36"
            case 30:
                //Research Park
                return "38"
            case 32:
                //Stanford Menlo Park
                return "40"
            case 33:
                //Bohannon
                return "53"
            case 40:
                //Line Y
                return "2"
            case 42:
                //Line Y Limited
                return "44"
            case 43:
                //Line X Limited
                return "45"
            case 44:
                //Line C Limited
                return "46"
            case 46:
                //OCA
                return "56"
            case 47:
                //Electric N
                return "9"
            case 48:
                //Medical Center Limited
                return "22"
            case 49:
                //Medical Center Limited
                return "22"
            case 50:
                //EB
                return "55"
            case 51:
                //Electric 1050A
                return "28"
            case 52:
                //Electric BOH
                return "53"
            case 53:
                //Electric Y
                return "2"
            case 54:
                //Electric C
                return "4"
            case 55:
                //Electric MC
                return "22"
            case 56:
                //Electric MC-H
                return "50"
            case 57:
                //Electric O
                return "43"
            case 58:
                //Electric P
                return "20"
            case 59:
                //Electric RP
                return "38"
            case 60:
                //Electric SE
                return "18"
            case 61:
                //Electric SLAC
                return "8"
            case 62:
                //Electric SMP
                return "40"
            case 63:
                //Electric TECH
                return "54"
            case 64:
                //Electric V
                return "15"
            case 65:
                //Electric X
                return "3"
            case 67:
                //VA
                return "61"
            case 68:
                //HD
                return "59"
            case 69:
                //Line R
                return "62"
            case 70:
                //PT
                return nil
            case 71:
                //AE-F
                return nil
            case 72:
                //Special
                return nil
            case 73:
                //Charter
                return nil
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
