//
//  FileHelper.swift
//  StanfordBus
//
//  Created by Andrew Finke on 7/9/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

let MovedGTFSBundleKey = "Moved GTFS From Bundle"

class FileHelper: NSObject, SSZipArchiveDelegate {
    
    // The names of the files from the GTFS zip needed
    private static let gtfsFileNames = ["agency", "calendar_dates", "routes", "stop_times", "stops", "trips"]
    
    // Path to latest zipped gtfs data
    private static let tempZipPath = tempFolderPath.stringByAppendingPathComponent("temp.zip")
    // Path to the folder where the downloaded gtfs zip is stored and unzipped
    private static let tempFolderPath = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String).stringByAppendingPathComponent("TempGTFSFiles")
    
    private let fileManager = NSFileManager.defaultManager()
    
    /**
    Detects if the neccessary gtfs files are in place
    
    :returns: Whether the files exist
    */
    func hasCompletedInitalSetup() -> Bool {
        return NSFileManager.defaultManager().contentsOfDirectoryAtPath(Util.getTransitFilesBasepath(), error: nil)?.count > 1
    }
    
    /**
    Gets the latest GTFS data from the stanford website
    */
    func getLatestGTFSData() {
        if let url = NSURL(string: MargueriteGTFSDataURL) {
            let task = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if let data = data where error == nil {
                    println("Downloaded new gtfs data")
                    data.writeToFile(FileHelper.tempZipPath, atomically: true)
                    self.movedNewZipToTempFolder()
                }
            })
            task.resume()
        }
    }
    
    /**
    Detects the newest file in the folder at path
    
    :returns: The date of the newest file
    */
    private func getLatestFileInFolder(path: String) -> NSDate {
        let contents = fileManager.contentsOfDirectoryAtPath(path, error: nil) as! [String]
        var latestDate = NSDate(timeIntervalSince1970: 0)
        for fileName in contents {
            if fileName.pathExtension == "txt" {
                let path = path.stringByAppendingPathComponent(fileName)
                let attributes = fileManager.attributesOfItemAtPath(path, error: nil)
                if let modificationDate = attributes?[NSFileModificationDate] as? NSDate where latestDate.timeIntervalSinceDate(modificationDate) < 0 {
                    latestDate = modificationDate
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
        SSZipArchive.unzipFileAtPath(FileHelper.tempZipPath, toDestination: tempFolder, progressHandler: nil) { (path: String?, succeeded: Bool, error: NSError?) -> Void in
            var latestFileInTemp = self.getLatestFileInFolder(tempFolder)
            var latestFileInCurrent = self.getLatestFileInFolder(Util.getTransitFilesBasepath())
            println("--- New GTFS Data ---")
            println(latestFileInTemp)
            println(latestFileInCurrent)
            println("Unzipped new data")
            if latestFileInTemp.timeIntervalSinceDate(latestFileInCurrent) > 0 {
                println("Replacing older data")
                self.moveTempFilesToTransitFolder()
                DefaultsHelper.keyIs(true, key: NeedsDatabaseUpdateKey)
                DefaultsHelper.saveDataForKey(latestFileInTemp, key: "GTFS Date")
            } else {
                println("Keeping current data")
            }
            println("Clearing temp folder")
            let contents = self.fileManager.contentsOfDirectoryAtPath(tempFolder, error: nil) as! [String]
            for fileName in contents {
                self.fileManager.removeItemAtPath(tempFolder.stringByAppendingPathComponent(fileName), error: nil)
            }
            println("--- Handled GTFS Data ---")
        }
    }
    
    /**
    Moves the newer files to the main transit files folder
    */
    private func moveTempFilesToTransitFolder() {
        let tempFolder = FileHelper.tempFolderPath
        for fileName in FileHelper.gtfsFileNames {
            let destinationPath = Util.getTransitFilesBasepath().stringByAppendingPathComponent(fileName + ".txt")
            if NSFileManager.defaultManager().fileExistsAtPath(destinationPath) {
                NSFileManager.defaultManager().removeItemAtPath(destinationPath, error: nil)
            }
            NSFileManager.defaultManager().moveItemAtPath(tempFolder.stringByAppendingPathComponent(fileName + ".txt"), toPath: destinationPath, error: nil)
        }
    }
    
    /**
    Moves the bundled gtfs data to the temp folder as if downloaded
    */
    class func moveBundleToTempFolder() {
        for fileNames in gtfsFileNames {
            if let path = NSBundle.mainBundle().pathForResource("BundledGTFS", ofType: "zip") {
                var isDir : ObjCBool = false
                NSFileManager.defaultManager().copyItemAtPath(path, toPath: FileHelper.tempFolderPath.stringByAppendingPathComponent("temp.zip"), error: nil)
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
        checkFolder("RouteBubbles")
        checkFolder("RouteBubbleCollections")
    }
    
    /**
    If the folder exists, great do nothing. If it doesn't exist create it.
    */
    private class func checkFolder(folderName: String) {
        let path = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString).stringByAppendingPathComponent(folderName)
        let fileManager = NSFileManager.defaultManager()
        var isDir : ObjCBool = false
        if !fileManager.fileExistsAtPath(path, isDirectory:&isDir) {
            fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
    }
}
