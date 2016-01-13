//
//  AboutTableViewController.swift
//  A UITableViewController for displaying information about the app.
//
//  Created by Kevin Conley on 3/11/15.
//  Copyright (c) 2015 Kevin Conley. All rights reserved.
//

import UIKit
import SafariServices

class AboutTableViewController: UITableViewController, SFSafariViewControllerDelegate {
    
    private var seperatorColor: UIColor!
    private var tableViewBackgroundColor: UIColor!
    
    // MARK: - Strings
    
    private let headers: [String?] = [NSLocalizedString("Credits Header", comment: ""), NSLocalizedString("Contact Marguerite Header", comment: ""), NSLocalizedString("Open-source Header", comment: ""), NSLocalizedString("Other Apps Header", comment: ""), nil]
    private let creditsStrings: [String] = [NSLocalizedString("Updated Version Title", comment: ""), NSLocalizedString("Original App Title", comment: ""), NSLocalizedString("Branding Title", comment: ""), NSLocalizedString("Misc. Images Title", comment: "")]
    private let contactStrings: [String] = [NSLocalizedString("Main Office Title", comment: ""), NSLocalizedString("Lost and Found Title", comment: ""), NSLocalizedString("Website Title", comment: ""), NSLocalizedString("Website Map Title", comment: "")]

    // MARK: - Links
    
    private let officePhoneNumber = "650-724-9339"
    private let lostAndFoundPhoneNumber = "650-724-4309"
    private let websiteURL = "http://transportation.stanford.edu/marguerite"
    private let gitHubURL = "http://atfinkeproductions.com/Marguerite"
    
    // MARK: - View Transitions
    
    override func viewDidLoad() {
        tableViewBackgroundColor = tableView.backgroundColor
        seperatorColor = tableView.separatorColor
        updateTheme()
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
    
    // MARK: - Actions
    
    @IBAction private func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = creditsStrings[indexPath.row]
        case 1:
            cell.textLabel?.text = contactStrings[indexPath.row]
        case 2:
            cell.textLabel?.text = NSLocalizedString("GitHub Title", comment: "")
        case 3:
            cell.textLabel?.text = "Stanford Laundry Rooms"
        default:
            break
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                callPhoneNumber(officePhoneNumber)
            case 1:
                callPhoneNumber(lostAndFoundPhoneNumber)
            case 2:
                openSafariController(websiteURL)
            default:
                break
            }
        case 2:
            openSafariController(gitHubURL)
        case 3:
            openSafariController("http://atfinkeproductions.com/Laundry")
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return NSLocalizedString("Open-source Footer", comment: "")
        }
        return nil
    }
    
    // MARK: - URL Convenience Methods
    
    private func callPhoneNumber(telephoneNumberString: String) {
        if let url = NSURL(string: "tel://\(telephoneNumberString)") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    private func openSafariController(urlString: String) {
        if let url = NSURL(string: urlString) {
            if #available(iOS 9.0, *) {
                UIApplication.sharedApplication().statusBarStyle = .Default
                UIBarButtonItem.appearance().tintColor = UIColor.cardinalColor()
                let controller = SFSafariViewController(URL: url)
                controller.delegate = self
                presentViewController(controller, animated: true, completion: nil)
            } else {
                UIApplication.sharedApplication().openURL(url)
            }
            
        }
    }
    
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
}
