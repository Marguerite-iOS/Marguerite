//
//  FileHelper.swift
//  Marguerite
//
//  Created by Andrew Finke on 7/9/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

let appGroupIdentifier = "group.edu.stanford.Marguerite"
let MovedGTFSBundleKey = "Moved GTFS From Bundle"

class FileHelper: NSObject, SSZipArchiveDelegate {
    
    private let fileManager = NSFileManager.defaultManager()
    
    // The names of the files from the GTFS zip needed
    private static let gtfsFileNames = ["agency", "calendar_dates", "routes", "stop_times", "stops", "trips"]
    private static let documentsPath =  NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    
    // Path to the folder where the downloaded gtfs zip is stored and unzipped
    private static let tempFolderPath = documentsPath.stringByAppendingString("/TempGTFSFiles")
    
    // Path to latest zipped gtfs data
    private static let tempZipPath: String  = tempFolderPath.stringByAppendingString("/temp.zip")
    
    /**
    Detects if the neccessary gtfs files are in place
    
    - returns: Whether the files exist
    */
    var hasCompletedInitalSetup: Bool {
        return (try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(Util.getTransitFilesBasepath()))?.count > 1
    }
    
    /**
    Gets the latest GTFS data from the stanford website
    */
    func getLatestGTFSData() {
        if let url = NSURL(string: MargueriteGTFSDataURL) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if let data = data where error == nil {
                    print("Downloaded new gtfs data")
                    data.writeToFile(FileHelper.tempZipPath, atomically: true)
                    self.movedNewZipToTempFolder()
                }
            })
            task.resume()
        }
    }
    
    /**
    Detects the newest file in the folder at path
    
    - returns: The date of the newest file
    */
    private func getLatestFileInFolder(path: String) -> NSDate {
        var latestDate = NSDate(timeIntervalSince1970: 0)
        if let contents = try? fileManager.contentsOfDirectoryAtPath(path) {
            for fileName in contents {
                if let url = NSURL(string: fileName) where url.pathExtension == "txt" {
                    let path = path.stringByAppendingString("/" + fileName)
                    let attributes = try? fileManager.attributesOfItemAtPath(path)
                    if let modificationDate = attributes?[NSFileModificationDate] as? NSDate where latestDate.timeIntervalSinceDate(modificationDate) < 0 {
                        latestDate = modificationDate
                    }
                }
            }
        }
        return latestDate
    }
    
    /**
    Starts to unzip the gtfs zip file
    */
    private func movedNewZipToTempFolder() {
        let tempFolder = FileHelper.tempFolderPath
        let tempZipPath = FileHelper.tempZipPath
        
        SSZipArchive.unzipFileAtPath(tempZipPath, toDestination: tempFolder, progressHandler: nil) { (path: String!, succeeded: Bool, error: NSError!) -> Void in
            let latestFileInTemp = self.getLatestFileInFolder(tempFolder)
            let latestFileInCurrent = self.getLatestFileInFolder(Util.getTransitFilesBasepath())
            print("--- New GTFS Data ---")
            print("Downloaded: " + latestFileInTemp.description)
            print("Current: " + latestFileInCurrent.description)
            print("Unzipped new data")
            if latestFileInTemp.timeIntervalSinceDate(latestFileInCurrent) > 0 {
                print("Replacing older data")
                self.moveTempFilesToTransitFolder()
                DefaultsHelper.keyIs(true, key: DataKey.NeedsDatabaseUpdate.rawValue)
                DefaultsHelper.saveDataForKey(latestFileInTemp, key: "GTFS Date")
            } else {
                print("Keeping current data")
            }
            print("Clearing temp folder")
            if let contents = try? self.fileManager.contentsOfDirectoryAtPath(tempFolder) {
                for fileName in contents {
                    do {
                        try self.fileManager.removeItemAtPath(tempFolder.stringByAppendingString("/" + fileName))
                    } catch {
                    }
                }
            }
            print("--- Handled GTFS Data ---")
        }
    }
    
    /**
    Moves the newer files to the main transit files folder
    */
    private func moveTempFilesToTransitFolder() {
        let tempFolder = FileHelper.tempFolderPath
        for fileName in FileHelper.gtfsFileNames {
            let destinationPath = Util.getTransitFilesBasepath().stringByAppendingString("/" + fileName + ".txt")
            if NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(destinationPath)
                } catch _ {
                }
            }
            do {
                try NSFileManager.defaultManager().moveItemAtPath(tempFolder.stringByAppendingString("/" + fileName + ".txt"), toPath: destinationPath)
            } catch _ {
            }
        }
    }
    
    /**
    Moves the bundled gtfs data to the temp folder as if downloaded
    */
    class func moveBundleToTempFolder() {
        if let path = NSBundle.mainBundle().pathForResource("BundledGTFS", ofType: "zip") {
            do {
                try NSFileManager.defaultManager().copyItemAtPath(path, toPath: tempFolderPath.stringByAppendingString("/temp.zip"))
            } catch {
                print(error)
            }
        }
        ShuttleSystem.sharedInstance.fileHelper.movedNewZipToTempFolder()
    }
    
    /**
    Builds the folders needed
    */
    class func ensureFolderExistance() {
        checkFolder("GTFSFiles")
        checkFolder("TempGTFSFiles")
    }
    
    /**
    If the folder exists, great do nothing. If it doesn't exist create it.
    */
    private class func checkFolder(folderName: String) {
        let path = (documentsPath as NSString).stringByAppendingPathComponent(folderName)
        let fileManager = NSFileManager.defaultManager()
        var isDir: ObjCBool = false
        if !fileManager.fileExistsAtPath(path, isDirectory:&isDir) {
            var error: NSError?
            do {
                try fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
            print(error)
        }
    }
}
