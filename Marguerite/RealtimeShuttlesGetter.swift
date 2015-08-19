//
//  RealtimeShuttlesGetter.swift
//  A convenience class for getting information about real-time locations of
//  Marguerite shuttle buses.
//
//  A lot of the details of this implementation were reverse-engineered from
//  the Marguerite web-based live shuttle map (javascript):
//  http://lbre-apps.stanford.edu/transportation/stanford_ivl/
//
//  Created by Kevin Conley on 3/8/15.
//  Copyright (c) 2015 Kevin Conley. All rights reserved.
//

import UIKit
import CoreLocation
import Crashlytics

protocol RealtimeShuttlesGetterProtocol {
    func didUpdateShuttles(shuttlesInfo: [[String:String]], mappingInfo: [String:String])
    func busUpdateDidFail(error: NSError)
}

class RealtimeShuttlesGetter: NSObject, NSXMLParserDelegate {
    
    // MARK: - Public API
    
    private var urlString: String
    var delegate: RealtimeShuttlesGetterProtocol?
    
    /**
    Refresh the buses by downloading the XML feed, asynchronously.
    */
    func update() {
        if let url = NSURL(string: urlString) {
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)) { () -> Void in
                if let parser = NSXMLParser(contentsOfURL: url) {
                    parser.delegate = self
                    if !parser.parse() {
                        self.delegate?.busUpdateDidFail(NSError(domain: "edu.stanford.Marguerite", code: 1, userInfo: nil))
                    }
                }
            }
        }
    }
    
    // MARK: - Initializer
    
    init(urlString: String) {
        self.urlString = urlString
    }
    
    // MARK: - NSXMLParserDelegate
    
    private struct XMLElement {
        static let vehicle = "vehicle"
        
        static let commStatus = "comm-status"
        static let gpsStatus = "gps-status"
        static let opStatus = "op-status"
        
        static let goodStatus = "good"
        static let noStatus = "none"
    }
    
    private var parsingVehicle = false
    private var currentElement: String?
    private var currentVehicleDictionary: [String:String]?
    private var vehicleDictionaries = [[String:String]]()
    
    func parserDidStartDocument(parser: NSXMLParser) {
        vehicleDictionaries = []
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        if !parsingVehicle && elementName == XMLElement.vehicle, let gpsStatus = attributeDict[XMLElement.gpsStatus] as? String, opStatus = attributeDict[XMLElement.opStatus] as? String where gpsStatus == XMLElement.goodStatus {
            currentVehicleDictionary = [String:String]()
            parsingVehicle = true
        }
        currentElement = elementName
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        if parsingVehicle, let current = currentElement where currentVehicleDictionary != nil {
            currentVehicleDictionary?[current] = string
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == XMLElement.vehicle {
            if parsingVehicle, let currentVehicleDictionary = currentVehicleDictionary {
                vehicleDictionaries.append(currentVehicleDictionary)
                self.currentVehicleDictionary = nil
            }
            parsingVehicle = false
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        // Construct vehicle ID string for POST request
        let vehicleIdString = extractVehicleIdsFromBusDictionaries(vehicleDictionaries)
        
        // Perform POST request
        
        let url = NSURL(string: MargueriteShuttleLookupURL)
        
        if url == nil {
            return
        }
        
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        let postString = "name=\(vehicleIdString)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            if error != nil {
                self.delegate?.busUpdateDidFail(NSError(domain: "edu.stanford.Marguerite", code: 1, userInfo: nil))
                println(error)
                return
            }
            var jsonError: NSError? = nil
            if let jsonData = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as? [String:AnyObject], mappings = jsonData["DATA"] as? [[AnyObject]] {
                var vehicleIdsToFareboxIds = [String:String]()
                for mapping  in mappings as [[AnyObject]] {
                    // Each input bus id returns as an array of objects with the bus id and farebox id of the bus's route
                    if mapping.count == 2 {
                        vehicleIdsToFareboxIds[String(format: "%@", mapping[0].description)] = self.getRouteIdWithFareboxId(String(format: "%@", mapping[1].description))
                    }
                }
                self.delegate?.didUpdateShuttles(self.vehicleDictionaries, mappingInfo: vehicleIdsToFareboxIds)
            } else {
                println(error)
                self.delegate?.busUpdateDidFail(NSError(domain: "edu.stanford.Marguerite", code: 2, userInfo: nil))
            }
        })
    }
    
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        CLSLogv("Parsing error: %@", getVaList([parseError]))
    }
    
    /**
    Create a string of comma-separated vehicleIds from a list of bus XML dictionaries.
    
    :param: busDictionaries The list of bus dictionaries constructed from XML.
    
    :returns: The comma-separated string of vehicleIds.
    */
    private func extractVehicleIdsFromBusDictionaries(busDictionaries: [[String:String]]) -> String {
        var vehicleIds = [String]()
        
        for busDictionary in busDictionaries {
            if let vehicleId = busDictionary[ShuttleElement.name] {
                var id: String = vehicleId
                
                // this is a hack for SMP, following the web-based live map
                if busDictionary[ShuttleElement.routeId] == "8888" {
                    id = "8888"
                }
                
                vehicleIds.append(id)
            }
        }
        
        return ",".join(vehicleIds)
    }
    
    /**
    The XML feed identifies buses using a numeric ID in the name
    element, called a vehicle ID.
    
    The vehicle ID is translated to a farebox ID using the POST request in
    "parserDidEndDocument()".
    
    This function translates a farebox ID into the corresponding GTFS route ID.
    
    :param: fareboxId The fareboxId to translate to a GTFS route ID.
    
    :returns: The resulting GTFS route ID, or nil upon failure.
    */
    func getRouteIdWithFareboxId(fareboxId: String) -> String? {
        if let fareboxIdInt = fareboxId.toInt() {
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
                return "55";
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
