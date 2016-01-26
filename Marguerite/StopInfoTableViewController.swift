//
//  StopInfoTableViewController.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//



import UIKit

let showStopInfoSegueIdentifier = "showStopInfo"

class StopInfoTableViewController: UITableViewController {

    @IBOutlet private weak var favoriteBarButtonItem: UIBarButtonItem!
    
    private var seperatorColor: UIColor!
    private var tableViewBackgroundColor: UIColor!
    private let favFilledImage = UIImage(named: "FavFilled")
    private let favEmptyImage = UIImage(named: "FavEmpty")
    
    var stop: ShuttleStop? {
        didSet {
            updateFavoriteBarButtonItem()
            title = stop?.name
        }
    }
    
    /**
    Sets the table view header as small as possible to make the map at the top of the screen
    */
    override func viewDidLoad() {
        tableViewBackgroundColor = tableView.backgroundColor
        seperatorColor = tableView.separatorColor
        tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, tableView.bounds.width, 0.1))
        updateTheme()
        updateFavoriteBarButtonItem()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme", name: Notification.UpdatedTheme.rawValue, object: nil)
    }
    
    // MARK: - Night Mode
    
    /**
    Updates the UI colors
    */
    func updateTheme() {
        if ShuttleSystem.sharedInstance.nightModeEnabled {
            tableView.backgroundColor = UIColor.darkModeTableViewColor()
            tableView.separatorColor = UIColor.darkModeSeperatorColor()
        } else {
            tableView.backgroundColor = tableViewBackgroundColor
            tableView.separatorColor = seperatorColor
        }
    }
    
    // MARK: - Favoriting

    /**
    Updates the favorite bar button item image based on if the stop is in the user's favorites
    */
    private func updateFavoriteBarButtonItem() {
        guard let stop = stop else {
            favoriteBarButtonItem.image = favEmptyImage
            favoriteBarButtonItem.enabled = false
            return
        }
        favoriteBarButtonItem.image = ShuttleSystem.sharedInstance.isStopFavorited(stop) ? favFilledImage : favEmptyImage
    }
    
    /**
    Called when the user taps the favrotie bar button item. Tells the shuttle system manager to either remove it or add it to favorites and updates the bar button image
    */
    @IBAction private func favoriteButtonTapped(sender: AnyObject) {
        toggleFavoriteStatus()
        updateFavoriteBarButtonItem()
    }
    
    func toggleFavoriteStatus () {
        guard let stop = stop else {
            return
        }
        if ShuttleSystem.sharedInstance.isStopFavorited(stop) {
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.RemoveStopFromFavorites.rawValue, object: self.stop)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.AddStopToFavorites.rawValue, object: self.stop)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let _ = stop else {
            return 0
        }
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let stop = stop else {
            return 1
        }
        if section == 1 {
            return stop.stopTimes.count
        }
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("Upcoming Shuttles Header", comment: "")
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let stop = stop else {
            return nil
        }
        if section == 1 && stop.stopTimes.count == 0 {
            return NSLocalizedString("No Upcoming Shuttles Footer", comment: "")
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let stop = stop else {
            return UITableViewCell()
        }
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("MapCell", forIndexPath: indexPath) as! MapTableViewCell
            cell.displayStop(stop)
            cell.selectionStyle = .None
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! StopTimeTableViewCell
            cell.stopTime = stop.stopTimes[indexPath.row]
            return cell
        default:
            break
        }
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 200.0
        }
        return 44.0
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let stop = stop else {
            return
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 1 {
            let webViewNavigationController = UIStoryboard(name: "WebView", bundle: nil).instantiateInitialViewController() as! UINavigationController
            webViewNavigationController.modalPresentationStyle = .FormSheet
            (webViewNavigationController.topViewController as! WebViewController).route = stop.stopTimes[indexPath.row].route
            presentViewController(webViewNavigationController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Other
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @available(iOS 9.0, *)
    override func previewActionItems() -> [UIPreviewActionItem] {
        guard let stop = stop else {
            return []
        }
        var previewAction: UIPreviewAction!
        if ShuttleSystem.sharedInstance.isStopFavorited(stop) {
            previewAction = UIPreviewAction(title: "Remove from Favorites", style: .Destructive) { (previewAction: UIPreviewAction, viewController: UIViewController) -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.RemoveStopFromFavorites.rawValue, object: self.stop)
            }
        } else {
            previewAction = UIPreviewAction(title: "Add to Favorites", style: .Default) { (previewAction: UIPreviewAction, viewController: UIViewController) -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.AddStopToFavorites.rawValue, object: self.stop)
            }
        }
        return [previewAction]
    }
}
