//
//  WebViewController.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/30/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import WebKit
import Crashlytics

let showRouteInfoSegueIdentifier = "showRouteInfo"

class WebViewController: UIViewController, UIToolbarDelegate {

    private let webView = WKWebView()
    @IBOutlet private weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.setTitle(NSLocalizedString("Map Title", comment: ""), forSegmentAtIndex: 0)
            segmentedControl.setTitle(NSLocalizedString("Schedule Title", comment: ""), forSegmentAtIndex: 1)
        }
    }
    
    var route: ShuttleRoute! {
        didSet {
            webView.loadRequest(NSURLRequest(URL: getMapURLForRoute()))
            title = route.displayName
        }
    }
    
    override func viewDidLoad() {
        findHairlineImageViewUnder(navigationController?.navigationBar)?.hidden = true
        
        segmentedControl.frame = CGRectMake(0, 0, view.frame.width - 30, segmentedControl.frame.height)
        
        webView.setTranslatesAutoresizingMaskIntoConstraints(false)
        webView.backgroundColor = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
        
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[web]|", options: nil, metrics: nil, views: ["web":webView]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(44.0)-[web]|", options: nil, metrics: nil, views: ["web":webView]))
        view.sendSubviewToBack(webView)
        view.backgroundColor = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .Top
    }
    
    //From http://stackoverflow.com/questions/25392469/how-to-hide-uinavigationbar-hairline-with-swift
    /**
    Hides the thin line between the navigation bar and toolbar
    */
    private func findHairlineImageViewUnder(view:UIView!) -> UIView? {
        if view is UIImageView && view.bounds.size.height <= 1.0 {
            return view
        }
        
        for subview in view.subviews as! [UIView] {
            if let foundView = self.findHairlineImageViewUnder(subview) {
                return foundView
            }
        }
        
        return nil
    }
    
    // MARK: - Route URLs
    
    /**
    Some of the routes have bogus URLs, so handle those cases with this function.
    
    :param: route The route.
    
    :returns: The URL for the map of the given route.
    */
    private func getMapURLForRoute() -> NSURL {
        switch route!.shortName.lowercaseString {
        case "w":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/w/map.pdf")!
        case "mc-hol":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/mch/map.pdf")!
        default:
            return route!.routeURL.URLByAppendingPathComponent("/map.pdf")
        }
    }

    /**
    Some of the routes have bogus URLs, so handle those cases with this function.
    
    :param: route The route.
    
    :returns: The URL for the schedule of the given route.
    */
    private func getScheduleURLForRoute() -> NSURL {
        switch route!.shortName.lowercaseString {
        case "w":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/w/map.pdf")!
        case "eb ex":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/eb/eb.pdf")!
        case "mc-hol":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/mch/mch.pdf")!
        case "h-dir":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/hd/hd.pdf")!
        case "se":
            return isSESpecial() ? NSURL(string: "http://transportation.stanford.edu/marguerite/sesp/sesp.pdf")! : route!.routeURL.URLByAppendingPathComponent("/map.pdf")
        default:
            return route!.routeURL.URLByAppendingPathComponent("/" + route!.shortName!.lowercaseString + ".pdf")
        }
    }
    
    /**
    During the summer the shopping express has a special version.
    */
    private func isSESpecial() -> Bool {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if formatter.dateFromString("2015-09-13")?.timeIntervalSinceNow > 0 {
            return true
        }
        return false
    }
    
    /**
    Called when the user selects either map or schedule
    */
    @IBAction private func didChangeView(sender: AnyObject) {
        let url = segmentedControl.selectedSegmentIndex == 0 ? getMapURLForRoute() : getScheduleURLForRoute()
        webView.loadRequest(NSURLRequest(URL: url))
        if let newContent = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex) {
            Answers.logCustomEventWithName("Web View Content Update", customAttributes: ["SelectedContent" : newContent, "RouteName": route.shortName])
        }
    }
    
    /**
    Called when the user selects the actions button
    */
    @IBAction private func shareURL(sender: AnyObject) {
        let content = segmentedControl.selectedSegmentIndex == 0 ? NSLocalizedString("Map Title", comment: "") : NSLocalizedString("Schedule Title", comment: "")
        let string = route.displayName + " " + content
        Answers.logShareWithMethod("WebViewController",
            contentName: route.shortName + content,
            contentType: "url",
            contentId: "share-Web",
            customAttributes: [:])
        let url = segmentedControl.selectedSegmentIndex == 0 ? getMapURLForRoute() : getScheduleURLForRoute()
        let viewController = UIActivityViewController(activityItems: [string, url], applicationActivities: nil)
        presentViewController(viewController, animated: true, completion: nil)
    }
}
