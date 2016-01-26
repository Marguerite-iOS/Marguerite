//
//  LiveMapViewController.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import MapKit

class LiveMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet private weak var mapView: MKMapView! {
        didSet {
            mapView.region = ShuttleSystem.sharedInstance.region
            if #available(iOS 9.0, *) {
                mapView.showsTraffic = true
            }
        }
    }
    @IBOutlet private weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.setTitle(NSLocalizedString("All Title", comment: ""), forSegmentAtIndex: 0)
            segmentedControl.setTitle(NSLocalizedString("Stops Title", comment: ""), forSegmentAtIndex: 1)
            segmentedControl.setTitle(NSLocalizedString("Shuttles Title", comment: ""), forSegmentAtIndex: 2)
        }
    }
    
    private var loadingBarButton: UIBarButtonItem!
    private var reloadBarButton: UIBarButtonItem!
    
    private var stopAnnontations: [ShuttleSystemAnnotation] = []
    private var shuttleAnnontations: [ShuttleSystemAnnotation] = []
    
    private var showingStops = false
    private var showingShuttles = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Gathers the stop annotations
        ShuttleSystem.sharedInstance.stops.forEach({stopAnnontations.append($0.annotation)})
        
        // Gathers the live shuttle annotations
        ShuttleSystem.sharedInstance.shuttles.forEach({shuttleAnnontations.append($0.annotation)})
        
        updateMapAnnotations()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatingShuttles", name: Notification.UpdatingShuttles.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateShuttles", name: Notification.UpdatedShuttles.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFailToUpdateShuttles:", name: Notification.FailedToUpdateShuttles.rawValue, object: nil)
        
        loadingBarButton = createLoadingBarButtonItem()
        reloadBarButton = navigationItem.leftBarButtonItem!
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        ShuttleSystem.sharedInstance.viewingLiveMap = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        ShuttleSystem.sharedInstance.viewingLiveMap = false
    }
    
    /**
    Creates the loading bar button item for refreshes
    */
    private func createLoadingBarButtonItem() -> UIBarButtonItem {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityView.sizeToFit()
        activityView.startAnimating()
        return UIBarButtonItem(customView: activityView)
    }
    
    /**
    Called when updating begins
    */
    func updatingShuttles() {
        dispatch_async(dispatch_get_main_queue(), {
            self.navigationItem.leftBarButtonItem = self.loadingBarButton
        })
    }
    
    /**
    Called when the latest shuttle data is downloaded
    */
    func didUpdateShuttles() {
        dispatch_async(dispatch_get_main_queue(), {
            self.shuttleAnnontations.forEach({$0.hasUpdatedLocation = false})
            for shuttle in ShuttleSystem.sharedInstance.shuttles {
                var didFindShuttle = false
                for shuttleAnnontation in self.shuttleAnnontations {
                    if shuttleAnnontation.title == shuttle.annotationTitle {
                        didFindShuttle = true
                        shuttleAnnontation.hasUpdatedLocation = true
                        UIView.animateWithDuration(0.8, animations: {
                            shuttleAnnontation.coordinate = shuttle.location.coordinate
                        })
                    }
                }
                if !didFindShuttle {
                    let annotation = shuttle.annotation
                    annotation.hasUpdatedLocation = true
                    self.mapView.addAnnotation(annotation)
                    self.shuttleAnnontations.append(annotation)
                }
            }
            self.shuttleAnnontations = self.shuttleAnnontations.filter({ (annotation: ShuttleSystemAnnotation) -> Bool in
                if annotation.hasUpdatedLocation {
                    return true
                }
                else {
                    self.mapView.removeAnnotation(annotation)
                    return false
                }
            })
            self.navigationItem.prompt = ShuttleSystem.sharedInstance.shuttles.count == 0 ? NSLocalizedString("No Shuttles Message", comment: "") : nil
            self.navigationItem.leftBarButtonItem = self.reloadBarButton
        })
    }
    
    func didFailToUpdateShuttles(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
            self.navigationItem.leftBarButtonItem = self.reloadBarButton
            guard self.navigationController?.visibleViewController == self, let message = notification.object as? String else {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return
            }
            let alertController = UIAlertController(title: NSLocalizedString("Updating Shuttles Error Title", comment: ""), message: message + NSLocalizedString("Try Again Error Message End", comment: ""), preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Dismiss Button", comment: ""), style: .Cancel, handler: nil))
            let action = UIAlertAction(title: NSLocalizedString("Try Again Button", comment: ""), style: .Default) { (action) in
                ShuttleSystem.sharedInstance.updateRealtimeLocations()
            }
            alertController.addAction(action)
            self.presentViewController(alertController, animated: true, completion: nil)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    // MARK: - UI changes
    
    @IBAction private func refreshShuttles(sender: AnyObject) {
        ShuttleSystem.sharedInstance.updateRealtimeLocations()
    }
    
    /**
    Called when a user changes the selected segmented index and removes/adds corresponding annotations
    */
    @IBAction private func didChangeScope(sender: AnyObject) {
        updateMapAnnotations()
    }
    
    /**
    Updates the annotaions on the map based on the segmeneted control scope
    */
    private func updateMapAnnotations() {
        var shouldShowStops = false
        var shouldShowShuttles = false
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            shouldShowStops = true
            shouldShowShuttles = true
        case 1:
            shouldShowStops = true
            shouldShowShuttles = false
        case 2:
            shouldShowStops = false
            shouldShowShuttles = true
        default:
            break
        }
        
        if shouldShowStops && !showingStops {
            mapView.addAnnotations(stopAnnontations)
        } else if !shouldShowStops && showingStops {
            mapView.removeAnnotations(stopAnnontations)
        }
        if shouldShowShuttles && !showingShuttles {
            mapView.addAnnotations(shuttleAnnontations)
        } else if !shouldShowShuttles && showingShuttles {
            mapView.removeAnnotations(shuttleAnnontations)
        }
        showingStops = shouldShowStops
        showingShuttles = shouldShowShuttles
    }
    
    /**
    Sets the filled tab bar image. Setting the filled image in the storyboard does nothing. Could use a work around in the storyboard but code is easier to understand.
    
    - parameter imageName: The name of the filled image.
    */
    private func setFilledTabBarItemImage(imageName: String) {
        if let viewControllers = tabBarController?.viewControllers, navigationController = navigationController, index = viewControllers.indexOf(navigationController), items = tabBarController?.tabBar.items {
            items[index].selectedImage = UIImage(named: imageName)
        }
    }
    
    // MARK: - Map view delegate
    
    // delegate method for rendering the shuttles and stops
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        if let annotation = annotation as? ShuttleSystemAnnotation {
            switch annotation.type {
            case .Stop:
                let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Stop")
                pinView.pinColor = .Red
                pinView.canShowCallout = true
                pinView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
                return pinView
            case .Shuttle:
                return ShuttleSystemShuttleAnnotationView(annotation: annotation)
            default:
                break
            }
        }
        return nil
    }
    
    // moves stop annotations behind shuttle ones
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for annotationView in views {
            if let annotationView = annotationView as? ShuttleSystemShuttleAnnotationView, annotation = annotationView.annotation as? ShuttleSystemAnnotation where annotation.type == .Stop {
                annotationView.layer.zPosition = -1
            }
        }
    }
    
    // segues to detail controller for data type
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? ShuttleSystemAnnotation else {
            return
        }
        if let stop = annotation.object as? ShuttleStop {
            let stopInfoNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("StopInfoNavigationController") as! UINavigationController
            stopInfoNavigationController.modalPresentationStyle = .FormSheet
            let stopInfoTableViewController = stopInfoNavigationController.topViewController as! StopInfoTableViewController
            stopInfoTableViewController.stop = stop
            stopInfoTableViewController.navigationItem.leftBarButtonItem = stopInfoTableViewController.navigationItem.rightBarButtonItem
            stopInfoTableViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "dismiss")
            presentViewController(stopInfoNavigationController, animated: true, completion: nil)
        }
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // moves annotation to front when tapped
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let annotation = view.annotation as? ShuttleSystemAnnotation else {
            return
        }
        if annotation.type == .Stop {
            view.layer.zPosition = 0
        } else if annotation.type == .Shuttle {
            let webViewNavigationController = UIStoryboard(name: "WebView", bundle: nil).instantiateInitialViewController() as! UINavigationController
            webViewNavigationController.modalPresentationStyle = .FormSheet
            (webViewNavigationController.topViewController as! WebViewController).route = (annotation.object as! Shuttle).route
            presentViewController(webViewNavigationController, animated: true, completion: nil)
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
    // moves annotation to back when dseleted
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? ShuttleSystemAnnotation where annotation.type == .Stop {
            view.layer.zPosition = -1
        }
    }
   
    // MARK: - Other
    
    @IBAction func aboutButtonPressed(sender: AnyObject) {
        let aboutViewNavigationController = UIStoryboard(name: "AboutView", bundle: nil).instantiateInitialViewController() as! UINavigationController
        aboutViewNavigationController.modalPresentationStyle = .FormSheet
        presentViewController(aboutViewNavigationController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        title = NSLocalizedString("Live Map Title", comment: "")
        setFilledTabBarItemImage("MapFilled")
    }
}
