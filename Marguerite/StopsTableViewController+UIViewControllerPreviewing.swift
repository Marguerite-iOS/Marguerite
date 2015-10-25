//
//  StopsTableViewController+UIViewControllerPreviewing.swift
//  Marguerite
//
//  Created by Andrew Finke on 9/26/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.


import UIKit

extension StopsTableViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Create a detail view controller and set its properties.
        guard let stopInfoTableViewController = storyboard?.instantiateViewControllerWithIdentifier("StopInfoTableViewController") as? StopInfoTableViewController else { return nil }
        
        let stop = stopForIndexPath(indexPath)
        stopInfoTableViewController.stop = stop
        previewingContext.sourceRect = cell.frame
        
        return stopInfoTableViewController
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        showViewController(viewControllerToCommit, sender: self)
    }
}