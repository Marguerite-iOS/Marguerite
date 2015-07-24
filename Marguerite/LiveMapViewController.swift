//
//  LiveMapViewController.swift
//  StanfordBus
//
//  Created by Andrew Finke on 6/16/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit
import MapKit
import Crashlytics

class LiveMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    
    private var stopAnnontations: [ShuttleSystemAnnotation] = []
    private var shuttleAnnontations: [ShuttleSystemAnnotation] = []

    private var showingStops = false
    private var showingShuttles = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepares the MKMapView
        mapView.region = ShuttleSystem.sharedInstance.region()
        
        // Gathers the stop annotations
        for stop in ShuttleSystem.sharedInstance.stops {
            stopAnnontations.append(stop.annotation())
        }
        
        // Gathers the live shuttle annotations
        for shuttle in ShuttleSystem.sharedInstance.shuttles {
            if let annotation = shuttle.annotation() {
                shuttleAnnontations.append(annotation)
            }
        }
   
        updateMapAnnotations()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didUpdateShuttles", name: UpdatedShuttlesNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tappedRoute:", name: RouteAnnotationTappedNotification, object: nil)
        
        Answers.logContentViewWithName("LiveMapViewController", contentType: "View Controller", contentId: "content-LiveMap", customAttributes: [:])
    }
    
    /**
    Used for when the shuttle annotation is tapped
    */
    func tappedRoute(notification: NSNotification) {
        performSegueWithIdentifier(showRouteInfoSegueIdentifier, sender: notification.object)
    }
    
    /**
    Called when the latest shuttle data is downloaded
    */
    func didUpdateShuttles() {
        for shuttle in ShuttleSystem.sharedInstance.shuttles {
            if let coordinate = shuttle.location?.coordinate {
                var foundShuttle = false
                for shuttleAnnontation in shuttleAnnontations {
                    if shuttleAnnontation.title == shuttle.annotationTitle() {
                        foundShuttle = true
                        UIView.animateWithDuration(0.8, animations: {
                            shuttleAnnontation.coordinate = coordinate
                        })
                    }
                }
                if !foundShuttle {
                    if let annotation = shuttle.annotation() {
                        mapView.addAnnotation(annotation)
                        shuttleAnnontations.append(annotation)
                    }
                }
            }
        }
        navigationItem.prompt = ShuttleSystem.sharedInstance.shuttles.count == 0 ? NSLocalizedString("No Shuttles Message", comment: "") : nil
    }
    
    // MARK: - UI changes
    
    @IBAction private func refreshShuttles(sender: AnyObject) {
        Answers.logCustomEventWithName("Force Shuttles Refresh", customAttributes: [:])
        ShuttleSystem.sharedInstance.updateRealtimeLocations()
    }
    
    /**
    Called when a user changes the selected segmented index and removes/adds corresponding annotations
    */
    @IBAction private func didChangeScope(sender: AnyObject) {
        if let newScope = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex) {
            Answers.logCustomEventWithName("Live Map Scope Update", customAttributes: ["SelectedScope" : newScope])
        }
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
    
    :param: imageName The name of the filled image.
    */
    private func setFilledTabBarItemImage(imageName: String) {
        if let viewControllers = self.tabBarController?.viewControllers as? [UIViewController],
            index = find(viewControllers, navigationController!),
            items = self.tabBarController?.tabBar.items as? [UITabBarItem] {
                items[index].selectedImage = UIImage(named: imageName)
        }
    }
    
    // MARK: - Map view delegate

    // delegate method for rendering the shuttles and stops
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        if let annotation = annotation as? ShuttleSystemAnnotation {
            switch annotation.type {
            case .Stop:
                let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Stop")
                pinView.pinColor = .Red
                pinView.canShowCallout = true
                if !liveMapModeOnly {
                    pinView.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIView
                }
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
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        for annotationView in views {
            if let annotation = annotationView.annotation as? ShuttleSystemAnnotation where annotation.type == .Stop {
                annotationView.layer.zPosition = -1
            }
        }
    }
    
    // segues to detail controller for data type
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if let object: AnyObject = (view.annotation as? ShuttleSystemAnnotation)?.object, stop = object as? ShuttleStop {
            performSegueWithIdentifier(showStopInfoSegueIdentifier, sender: stop)
        }
    }
    
    // moves annotation to front when tapped
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let annotation = view.annotation as? ShuttleSystemAnnotation where annotation.type == .Stop {
            view.layer.zPosition = 0
        }
    }
    
    // moves annotation to back when dseleted
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        if let annotation = view.annotation as? ShuttleSystemAnnotation where annotation.type == .Stop {
            view.layer.zPosition = -1
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == showStopInfoSegueIdentifier, let stop = sender as? ShuttleStop {
            let controller = segue.destinationViewController as! StopInfoTableViewController
            controller.stop = stop
            Answers.logContentViewWithName("StopInfoTableViewController", contentType: "View Controller", contentId: "content-StopInfo", customAttributes: ["Origin": "LiveMapViewController", "StopName": stop.name, "StopID": stop.stopID])
        }
        else if segue.identifier == showRouteInfoSegueIdentifier, let route = sender as? ShuttleRoute {
            let controller = segue.destinationViewController as! WebViewController
            controller.route = route
            Answers.logContentViewWithName("WebViewController", contentType: "View Controller", contentId: "content-Web", customAttributes: ["Origin": "LiveMapViewController", "RouteName": route.shortName, "RouteID": route.routeID])
        }
    }

    // MARK: - Other
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl.setTitle(NSLocalizedString("All Title", comment: ""), forSegmentAtIndex: 0)
        segmentedControl.setTitle(NSLocalizedString("Stops Title", comment: ""), forSegmentAtIndex: 1)
        segmentedControl.setTitle(NSLocalizedString("Shuttles Title", comment: ""), forSegmentAtIndex: 2)
        
        title = NSLocalizedString("Live Map Title", comment: "")
        
        setFilledTabBarItemImage("MapFilled")
    }
}