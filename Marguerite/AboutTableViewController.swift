//
//  AboutTableViewController.swift
//  A UITableViewController for displaying information about the app.
//
//  Created by Kevin Conley on 3/11/15.
//  Copyright (c) 2015 Kevin Conley. All rights reserved.
//

import UIKit
import Crashlytics

class AboutTableViewController: UITableViewController {
    
    // MARK: - Strings
    
    private var lastUpdateString: String?
    
    private let headers: [String?] = [NSLocalizedString("Features Header", comment: ""), NSLocalizedString("Credits Header", comment: ""), NSLocalizedString("Contact Marguerite Header", comment: ""), NSLocalizedString("Open-source Header", comment: ""), nil]
    private let footers: [String?] = [NSLocalizedString("Features Footer", comment: ""), nil, nil, NSLocalizedString("Open-source Footer", comment: ""), nil]
    private let creditsStrings: [String] = [NSLocalizedString("Updated Version Title", comment: ""), NSLocalizedString("Original App Title", comment: ""), NSLocalizedString("Branding Title", comment: ""), NSLocalizedString("Misc. Images Title", comment: "")]
    private let contactStrings: [String] = [NSLocalizedString("Main Office Title", comment: ""), NSLocalizedString("Lost and Found Title", comment: ""),NSLocalizedString("Website Title", comment: ""), NSLocalizedString("Service Feedback Title", comment: "")]
    private let openSourceStrings: [String] = [NSLocalizedString("GitHub Title", comment: "")]

    // MARK: - Links
    
    private let officePhoneNumber = "650-724-9339"
    private let lostAndFoundPhoneNumber = "650-724-4309"
    private let websiteURL = "http://transportation.stanford.edu/marguerite"
    private let websiteServiceURL = "http://transportation.stanford.edu/margueritecomments/"
    private let gitHubURL = "https://github.com/Marguerite-iOS/Marguerite"
    
    // MARK: - View Transitions
    
    override func viewDidLoad() {
        if let date = DefaultsHelper.getObjectForKey("GTFS Date") as? NSDate {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MMMM dd, yyyy"
            lastUpdateString =  "GTFS data last updated " + formatter.stringFromDate(date)
        }
    }
    // MARK: - Actions
    
    @IBAction private func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        switch indexPath.section {
        case 1:
            cell.textLabel?.text = creditsStrings[indexPath.row]
        case 2:
            cell.textLabel?.text = contactStrings[indexPath.row]
        case 3:
            cell.textLabel?.text = openSourceStrings[indexPath.row]
        default:
            break
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 2:
            switch indexPath.row {
            case 0:
                Answers.logCustomEventWithName("Called Main Office", customAttributes: [:])
                callPhoneNumber(officePhoneNumber)
            case 1:
                Answers.logCustomEventWithName("Called Lost & Found", customAttributes: [:])
                callPhoneNumber(lostAndFoundPhoneNumber)
            case 2:
                Answers.logCustomEventWithName("Opened Main Website", customAttributes: [:])
                openURL(websiteURL)
            case 3:
                Answers.logCustomEventWithName("Opened Service Feedback", customAttributes: [:])
                openURL(websiteServiceURL)
            default:
                break
            }
        case 3:
            switch indexPath.row {
            case 0:
                Answers.logCustomEventWithName("Opened GitHub", customAttributes: [:])
                openURL(gitHubURL)
            default:
                break
            }
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 4 {
            return lastUpdateString
        }
        return footers[section]
    }
    
    // MARK: - URL Convenience Methods
    
    private func createEmail(emailAddress: String) {
        openURL("mailto:\(emailAddress)")
    }
    
    private func callPhoneNumber(telephoneUrl: String) {
        openURL("tel://\(telephoneUrl)")
    }
    
    private func openURL(urlString: String) {
        if let url = NSURL(string: urlString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}