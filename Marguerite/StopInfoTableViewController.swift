//
//  StopInfoTableViewController.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import Crashlytics

let showStopInfoSegueIdentifier = "showStopInfo"

class StopInfoTableViewController: UITableViewController {

    @IBOutlet private weak var favoriteBarButtonItem: UIBarButtonItem!
    
    private var seperatorColor: UIColor!
    private var tableViewBackgroundColor: UIColor!
    private let favFilledImage = UIImage(named: "FavFilled")
    private let favEmptyImage = UIImage(named: "FavEmpty")
    
    var stop: ShuttleStop! {
        didSet {
            updateFavoriteBarButtonItem()
            title = stop.name
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
    }
    
    // MARK: - Night Mode
    
    /**
    Updates the UI colors
    */
    private func updateTheme() {
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
        favoriteBarButtonItem.image = ShuttleSystem.sharedInstance.isStopFavorited(stop) ? favFilledImage : favEmptyImage
    }
    
    /**
    Called when the user taps the favrotie bar button item. Tells the shuttle system manager to either remove it or add it to favorites and updates the bar button image
    */
    @IBAction private func favoriteButtonTapped(sender: AnyObject) {
        if ShuttleSystem.sharedInstance.isStopFavorited(stop) {
            ShuttleSystem.sharedInstance.removeStopFromFavorites(stop)
        } else {
            ShuttleSystem.sharedInstance.addStopToFavorites(stop)
        }
        updateFavoriteBarButtonItem()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        if section == 1 && stop.stopTimes.count == 0 {
            return NSLocalizedString("No Upcoming Shuttles Footer", comment: "")
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 1, let route = stop.stopTimes[indexPath.row].route {
            Answers.logContentViewWithName("WebViewController", contentType: "View Controller", contentId: "content-Web", customAttributes: ["Origin": "StopInfoTableViewController", "RouteName": route.shortName, "RouteID": route.routeID])
            performSegueWithIdentifier(showRouteInfoSegueIdentifier, sender: route)
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == showRouteInfoSegueIdentifier, let route = sender as? ShuttleRoute {
            let controller = segue.destinationViewController as! WebViewController
            controller.route = route
        }
    }
    
    // MARK: - Other
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}