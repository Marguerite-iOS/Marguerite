//
//  StopsTableViewController.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import CoreLocation

class StopsTableViewController: UITableViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
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
    
    // MARK: - Actions
    
    /**
    Called when user taps info button
    */
    @IBAction func aboutButtonPressed(sender: AnyObject) {
        let aboutViewNavigationController = UIStoryboard(name: "AboutView", bundle: nil).instantiateInitialViewController() as! UINavigationController
        aboutViewNavigationController.modalPresentationStyle = .FormSheet
        presentViewController(aboutViewNavigationController, animated: true, completion: nil)
    }
    
    /**
     Called when user changes segmented controller selection
     */
    @IBAction private func didChangeScope(sender: AnyObject) {
        lastTableViewOffset[lastSelectedSegementIndex] = tableView.contentOffset.y
        tableView.reloadData()
        lastSelectedSegementIndex = segmentedControl.selectedSegmentIndex
        tableView.contentOffset.y = lastTableViewOffset[lastSelectedSegementIndex]
    }
    
    // MARK: - Interface
    
    /**
    Sets the filled tab bar image. Setting the filled image in the storyboard does nothing. Could use a work around in the storyboard but code is easier to understand.
    
    - parameter imageName: The name of the filled image.
    */
    private func setFilledTabBarItemImage(imageName: String) {
        if let viewControllers = self.tabBarController?.viewControllers,
            index = viewControllers.indexOf(navigationController!),
            items = self.tabBarController?.tabBar.items {
                items[index].selectedImage = UIImage(named: imageName)
        }
    }
    
    /**
     Loads interface item
     */
    private func configureInterface() {
        title = NSLocalizedString("Stops Title", comment: "")
        setFilledTabBarItemImage("BusFilled")
        updateTheme()
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        item.width = 24.0
        navigationItem.rightBarButtonItems = [navigationItem.rightBarButtonItem!, item]
    }
    
    /**
     Loads the table view properties and related vars
     */
    private func configureTableViewProperties() {
        seperatorColor = tableView.separatorColor
        if let height = navigationController?.navigationBar.frame.height {
            lastTableViewOffset = [-height - 20, -height - 20, -height - 20]
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
    
    // MARK: - Favorites
    
    /**
    Called when the user taps favorite button so that iPad & 3D touch users see adding animation while still looking at stop
    */
    func addStopToFavorites(notification: NSNotification) {
        guard let stop = notification.object as? ShuttleStop where ShuttleSystem.sharedInstance.favoriteStops.indexOf(stop) == nil else {
            return
        }
        
        ShuttleSystem.sharedInstance.addStopToFavorites(stop)
        if segmentedControl.selectedSegmentIndex == 1, let index = ShuttleSystem.sharedInstance.favoriteStops.indexOf(stop) {
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
        }
    }
    
    /**
     Called when the user taps favorite button so that iPad & 3D touch users see removing animation while still looking at stop
     */
    func removeStopFromFavorites(notification: NSNotification) {
        guard let stop = notification.object as? ShuttleStop, let index = ShuttleSystem.sharedInstance.favoriteStops.indexOf(stop) else {
            return
        }
        
        ShuttleSystem.sharedInstance.removeStopFromFavorites(stop)
        
        if segmentedControl.selectedSegmentIndex == 1 {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
        }
    }
    
    // MARK: - Size Changes
    
    /**
    Called when orientation change notification triggered
    */
    func orientationChanged() {
        let selectedIndexes = tableView.indexPathsForSelectedRows
        tableView.reloadData()
        if let indexPath = selectedIndexes?[0] {
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail", let indexPath = self.tableView.indexPathForSelectedRow {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! StopInfoTableViewController
            controller.stop = ShuttleSystem.sharedInstance.stopForIndexPath(indexPath, scope: segmentedControl.selectedSegmentIndex)
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            return ShuttleSystem.sharedInstance.favoriteStops.count
        case 2:
            return ShuttleSystem.sharedInstance.closestStops.count
        default:
            return ShuttleSystem.sharedInstance.stops.count
        }
    }
    
    // Gets the stop based on the scope of the stops determined by the segmented controller
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! StopTableViewCell
        cell.stop = ShuttleSystem.sharedInstance.stopForIndexPath(indexPath, scope: segmentedControl.selectedSegmentIndex)
        return cell
    }
    
    // Uses the image of the routes to determine the height of the cell
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = ShuttleSystem.sharedInstance.stopForIndexPath(indexPath, scope: segmentedControl.selectedSegmentIndex).getRouteBubblesImage(view.frame.width)?.size.height where height > 10.0 {
            return 44 + height
        }
        return 44
    }
    
    // MARK: - Other
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTableViewProperties()
        configureInterface()
        addNotificationObservers()
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "registerForPreviewing", userInfo: nil, repeats: false)
    }
    
    /**
     Registers for 3D touch after slight delay as registering at first launch oftern has forceTouchCapability returning no
     */
    func registerForPreviewing() {
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
            }
        }
    }
    
    /**
     Adds notification observers
     */
    func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme", name: Notification.UpdatedTheme.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideNearbyStops", name: Notification.LocationUnavailable.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showNearbyStops", name: Notification.LocationAvailable.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addStopToFavorites:", name: Notification.AddStopToFavorites.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeStopFromFavorites:", name: Notification.RemoveStopFromFavorites.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
}
