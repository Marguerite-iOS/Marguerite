//
//  ShuttleSystem+Formatters.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

extension ShuttleSystem {
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
}
