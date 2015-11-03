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
    
    // Called when user changes segmented controller selection
    @IBAction private func didChangeScope(sender: AnyObject) {
        lastTableViewOffset[lastSelectedSegementIndex] = tableView.contentOffset.y
        tableView.reloadData()
        lastSelectedSegementIndex = segmentedControl.selectedSegmentIndex
        tableView.contentOffset.y = lastTableViewOffset[lastSelectedSegementIndex]
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
        cell.stop = stopForIndexPath(indexPath)
        return cell
    }
    
    // Uses the image of the routes to determine the height of the cell
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = stopForIndexPath(indexPath).getRouteBubblesImage(view.frame.width)?.size.height where height > 10.0 {
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
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! StopInfoTableViewController
                controller.stop = stopForIndexPath(indexPath)
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Other
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTableViewProperties()
        configureInterface()
        addNotificationObservers()
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "registerForPreviewing", userInfo: nil, repeats: false)
    }
    
    func configureInterface() {
        title = NSLocalizedString("Stops Title", comment: "")
        setFilledTabBarItemImage("BusFilled")
        updateTheme()
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        item.width = 24.0
        navigationItem.rightBarButtonItems = [navigationItem.rightBarButtonItem!, item]
    }
    
    func configureTableViewProperties() {
        seperatorColor = tableView.separatorColor
        if let height =  navigationController?.navigationBar.frame.height {
            for var index = 0; index < 3; index++ {
                lastTableViewOffset.append(-height - 20)
            }
        }
        tableView.cellLayoutMarginsFollowReadableWidth = true
    }
    
    func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme", name: UpdatedThemeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideNearbyStops", name: LocationUnavailableNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showNearbyStops", name: LocationAvailableNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addStopToFavorites:", name: AddStopToFavoritesNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeStopFromFavorites:", name: RemoveStopFromFavoritesNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func registerForPreviewing() {
        if traitCollection.forceTouchCapability == .Available {
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
    }
    
    
    
    @IBAction func aboutButtonPressed(sender: AnyObject) {
        let aboutViewNavigationController = UIStoryboard(name: "AboutView", bundle: nil).instantiateInitialViewController() as! UINavigationController
        aboutViewNavigationController.modalPresentationStyle = .FormSheet
        presentViewController(aboutViewNavigationController, animated: true, completion: nil)
    }
    /**
    Gets the stop at index path based on the selected segemented control index
    
    - parameter indexPath: The index path
    
    - returns: The stop
    */
    func stopForIndexPath(indexPath: NSIndexPath) -> ShuttleStop {
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            return ShuttleSystem.sharedInstance.favoriteStops[indexPath.row]
        case 2:
            return ShuttleSystem.sharedInstance.closestStops[indexPath.row]
        default:
            return ShuttleSystem.sharedInstance.stops[indexPath.row]
        }
    }
    
    // MARK: - Favorites
    
    func addStopToFavorites(notification: NSNotification) {
        guard let stop = notification.object as? ShuttleStop where ShuttleSystem.sharedInstance.favoriteStops.indexOf(stop) == nil else {
            return
        }
        
        ShuttleSystem.sharedInstance.addStopToFavorites(stop)
        if segmentedControl.selectedSegmentIndex == 1, let index = ShuttleSystem.sharedInstance.favoriteStops.indexOf(stop)
        {
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
        }
    }
    
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
}
