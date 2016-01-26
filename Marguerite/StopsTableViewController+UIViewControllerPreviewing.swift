//
//  StopsTableViewController+UIViewControllerPreviewing.swift
//  Marguerite
//
//  Created by Andrew Finke on 1/26/16.
//  Copyright © 2016 Andrew Finke. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
extension StopsTableViewController: UIViewControllerPreviewingDelegate {
    /**
    Create a previewing view controller to be shown at "Peek".
    */
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Create a detail view controller and set its properties.
        guard let stopInfoTableViewController = storyboard?.instantiateViewControllerWithIdentifier("StopInfoTableViewController") as? StopInfoTableViewController else { return nil }
        
        let stop = ShuttleSystem.sharedInstance.stopForIndexPath(indexPath, scope: segmentedControl.selectedSegmentIndex)
        stopInfoTableViewController.stop = stop
        previewingContext.sourceRect = cell.frame
        if stop.stopTimes.count == 0 {
            stopInfoTableViewController.preferredContentSize = CGSize(width: 0.0, height: stopInfoTableViewController.tableView.contentSize.height)
        }
        
        return stopInfoTableViewController
    }
    /**
     Present the view controller for the "Pop" action.
     */
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        showViewController(viewControllerToCommit, sender: self)
    }
}