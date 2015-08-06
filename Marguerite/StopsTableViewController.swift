//
//  StopsTableViewController.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import CoreLocation
import Crashlytics

class StopsTableViewController: UITableViewController {
    
    @IBOutlet private weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.setTitle(NSLocalizedString("All Title", comment: ""), forSegmentAtIndex: 0)
            segmentedControl.setTitle(NSLocalizedString("Favorites Title", comment: ""), forSegmentAtIndex: 1)
        }
    }
    @IBOutlet private weak var nightModeBarButtonItem: UIBarButtonItem!
    
    private var lastTableViewOffset: [CGFloat] = []
    private var lastSelectedSegementIndex = 0
    
    private var seperatorColor: UIColor!
    private let sunFilledImage = UIImage(named: "SunFilled")
    private let sunEmptyImage = UIImage(named: "SunEmpty")
    
    override func viewDidLoad() {
        Answers.logContentViewWithName("StopsTableViewController", contentType: "View Controller", contentId: "content-Stops", customAttributes: [:])
    }
    
    /**
    Sets the filled tab bar image. Setting the filled image in the storyboard does nothing. Could use a work around in the storyboard but code is easier to understand.
    
    :param: imageName The name of the filled image.
    */
    private func setFilledTabBarItemImage(imageName: String) {
        if let viewControllers = self.tabBarController?.viewControllers as? [UIViewController],
            index = find(viewControllers, navigationController!),
            items = self.tabBarController?.tabBar.items as? [UITabBarItem] {
            items[index].selectedImage = UIImage(named: imageName)
        }
    }
    
    // Called when user changes segmented controller selection
    @IBAction private func didChangeScope(sender: AnyObject) {
        lastTableViewOffset[lastSelectedSegementIndex] = tableView.contentOffset.y
        tableView.reloadData()
        lastSelectedSegementIndex = segmentedControl.selectedSegmentIndex
        tableView.contentOffset.y = lastTableViewOffset[lastSelectedSegementIndex]
        if let newScope = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex) {
            Answers.logCustomEventWithName("Stops Scope Update", customAttributes: ["SelectedScope" : newScope])
        }
    }
    
    
    // MARK: - Night Mode
    
    /**
    Called when the sun image is tapped
    */
    @IBAction private func toggleNightMode(sender: AnyObject) {
        ShuttleSystem.sharedInstance.nightModeEnabled = !ShuttleSystem.sharedInstance.nightModeEnabled
        nightModeBarButtonItem.image = ShuttleSystem.sharedInstance.nightModeEnabled ? sunEmptyImage : sunFilledImage
    }
    
    /**
    Updates the UI colors
    */
    func updateTheme() {
        if ShuttleSystem.sharedInstance.nightModeEnabled {
            tableView.backgroundColor = UIColor.darkModeCellColor()
            tableView.separatorColor = UIColor.darkModeSeperatorColor()
        } else {
            tableView.backgroundColor = UIColor.whiteColor()
            tableView.separatorColor = seperatorColor
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return ShuttleSystem.sharedInstance.stops.count
        case 1:
            return ShuttleSystem.sharedInstance.favoriteStops.count
        case 2:
            return ShuttleSystem.sharedInstance.closestStops.count
        default:
            return 0
        }
    }
    
    // Gets the stop based on the scope of the stops determined by the segmented controller
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! StopTableViewCell
        cell.stop = stopForIndexPath(indexPath)
        return cell
    }
    
    // Uses the image of the routes to determine the height of the cell
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = stopForIndexPath(indexPath).routeBubblesImage?.size.height where height > 10.0 {
            return 44 + height
        }
        return 44
    }
    
    // MARK: - Location Updates
    
    /**
    Hides the nearby stops segment when the user's location is unavailable
    */
    func hideNearbyStops() {
        if segmentedControl.numberOfSegments == 3 {
            segmentedControl.removeSegmentAtIndex(2, animated: false)
        }
    }
    
    /**
    Shows the nearby stops segment when the user's location is available
    */
    func showNearbyStops() {
        if segmentedControl.numberOfSegments == 2 {
            segmentedControl.insertSegmentWithTitle(NSLocalizedString("Nearby Title", comment: ""), atIndex: 2, animated: false)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = tableView.indexPathForSelectedRow() {
            let stop = stopForIndexPath(indexPath)
            let controller = segue.destinationViewController as! StopInfoTableViewController
            controller.stop = stop
            Answers.logContentViewWithName("StopInfoTableViewController", contentType: "View Controller", contentId: "content-StopInfo", customAttributes: ["Origin": "StopsTableViewController", "StopName": stop.name, "StopID": stop.stopID])
        }
    }
    
    // MARK: - Other
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        title = NSLocalizedString("Stops Title", comment: "")
        
        setFilledTabBarItemImage("BusFilled")
        seperatorColor = tableView.separatorColor
        updateTheme()
        
        for var index = 0; index < 3; index++ {
            if let height =  navigationController?.navigationBar.frame.height {
                lastTableViewOffset.append(-height - 20)
            }
        }
        
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        item.width = 24.0
        navigationItem.rightBarButtonItems = [navigationItem.rightBarButtonItem!, item]
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme", name: UpdatedThemeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideNearbyStops", name: LocationUnavailableNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showNearbyStops", name: LocationAvailableNotification, object: nil)
    }
    
    /**
    Gets the stop at index path based on the selected segemented control index
    
    :param: indexPath The index path
    
    :returns: The stop
    */
    private func stopForIndexPath(indexPath: NSIndexPath) -> ShuttleStop {
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            return ShuttleSystem.sharedInstance.favoriteStops[indexPath.row]
        case 2:
            return ShuttleSystem.sharedInstance.closestStops[indexPath.row]
        default:
            break
        }
        return ShuttleSystem.sharedInstance.stops[indexPath.row]
    }
}
