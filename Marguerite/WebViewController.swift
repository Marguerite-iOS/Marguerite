//
//  WebViewController.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/30/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import WebKit

let showRouteInfoSegueIdentifier = "showRouteInfo"

class WebViewController: UIViewController, WKNavigationDelegate {

    private let progressView = UIProgressView(progressViewStyle: .Bar)
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
    
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.alpha = 0.0
        
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[web]|", options: [], metrics: nil, views: ["web":webView]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[web]|", options: [], metrics: nil, views: ["web":webView]))
        view.sendSubviewToBack(webView)
        view.backgroundColor = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
        
        createProgressView()
    }
    
    //From http://stackoverflow.com/questions/25392469/how-to-hide-uinavigationbar-hairline-with-swift
    /**
    Hides the thin line between the navigation bar and toolbar
    */
    func findHairlineImageViewUnder(view: UIView?) -> UIView? {
        
        guard let view = view else {
            return nil
        }
        
        if view is UIImageView && view.bounds.size.height <= 1.0 {
            return view
        }
        
        for subview in view.subviews {
            if let foundView = self.findHairlineImageViewUnder(subview) {
                return foundView
            }
        }
        
        return nil
    }
    
    // MARK: - Web View
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        showProgressView()
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if webView.alpha != 1.0 {
            webView.alpha = 1.0
        }
        hideProgressView()
    }
    
    // MARK: - Progress View
    
    func createProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor.whiteColor()
        view.addSubview(progressView)
        let widthConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|[progressView]|", options : NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["progressView": progressView])
        let heightConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|[topLayoutGuide][progressView]", options : NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["progressView": progressView, "topLayoutGuide" : topLayoutGuide])
        view.addConstraints(heightConstraint)
        view.addConstraints(widthConstraint)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    func progess(progress: Float) {
        dispatch_async(dispatch_get_main_queue(), {
            self.progressView.setProgress(max(progress*(19.0/20.0) + 0.05, self.progressView.progress), animated: true)
        })
    }
    
    func showProgressView() {
        progressView.setProgress(max(0.05, self.progressView.progress), animated: false)
        progressView.hidden = false
    }
    
    func hideProgressView() {
        UIView.animateWithDuration(0.4, delay: 0.75, options: [], animations: {
            self.progressView.alpha = 0.0
            }, completion: { finished in
                self.progressView.hidden = true
                self.progressView.alpha = 1.0
                self.progressView.progress = 0.0
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "estimatedProgress" {
            progess(Float((object as! WKWebView).estimatedProgress))
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Route URLs
    
    /**
    Some of the routes have bogus URLs, so handle those cases with this function.
    
    - parameter route: The route.
    
    - returns: The URL for the map of the given route.
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
    
    - parameter route: The route.
    
    - returns: The URL for the schedule of the given route.
    */
    private func getScheduleURLForRoute() -> NSURL {
        switch route.shortName.lowercaseString {
        case "w":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/w/map.pdf")!
        case "eb ex":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/eb/eb.pdf")!
        case "mc-hol":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/mch/mch.pdf")!
        case "h-dir":
            return NSURL(string: "http://transportation.stanford.edu/marguerite/hd/hd.pdf")!
        case "se":
            return isSESpecial() ? NSURL(string: "http://transportation.stanford.edu/marguerite/sesp/sesp.pdf")! : route.routeURL.URLByAppendingPathComponent("/" + route.shortName.lowercaseString + ".pdf")
        default:
            return route.routeURL.URLByAppendingPathComponent("/" + route.shortName.lowercaseString + ".pdf")
        }
    }
    
    /**
    During the summer the shopping express has a special version.
    */
    private func isSESpecial() -> Bool {
        if ShuttleSystem.sharedInstance.databaseDateFormatter.dateFromString("2015-09-10")?.timeIntervalSinceNow > 0 {
            return true
        }
        return false
    }
    
    // MARK: - Actions
    
    /**
    Called when the user taps the close button
    */
    @IBAction func dismiss(sender: AnyObject) {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
    Called when the user selects either map or schedule
    */
    @IBAction private func didChangeView(sender: AnyObject) {
        let url = segmentedControl.selectedSegmentIndex == 0 ? getMapURLForRoute() : getScheduleURLForRoute()
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    /**
    Called when the user selects the actions button
    */
    @IBAction private func shareURL(sender: AnyObject) {
        let content = segmentedControl.selectedSegmentIndex == 0 ? NSLocalizedString("Map Title", comment: "") : NSLocalizedString("Schedule Title", comment: "")
        let string = route.displayName + " " + content
        let url = segmentedControl.selectedSegmentIndex == 0 ? getMapURLForRoute() : getScheduleURLForRoute()
        let viewController = UIActivityViewController(activityItems: [string, url], applicationActivities: nil)
        viewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        presentViewController(viewController, animated: true, completion: nil)
    }
}
