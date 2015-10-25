//
//  StopInfoTableViewController+UIViewControllerPreviewing.swift
//  Marguerite
//
//  Created by Andrew Finke on 9/26/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.

import UIKit

extension StopInfoTableViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Create a detail view controller and set its properties.
        guard let webViewController = storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as? WebViewController else { return nil }
        webViewController.route = stop.stopTimes[indexPath.row].route
        previewingContext.sourceRect = cell.frame
        
        return webViewController
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        showViewController(viewControllerToCommit, sender: self)
        (viewControllerToCommit as! WebViewController).findHairlineImageViewUnder(navigationController?.navigationBar)?.hidden = true
    }
    
}
