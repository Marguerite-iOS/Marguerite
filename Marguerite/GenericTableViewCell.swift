//
//  GenericTableViewCell.swift
//  Marguerite
//
//  Created by Andrew Finke on 10/30/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class GenericTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme", name: Notification.UpdatedTheme.rawValue, object: nil)
        selectedBackgroundView = UIView()
        updateTheme()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /**
     Updates the UI colors
     */
    func updateTheme() {
        if ShuttleSystem.sharedInstance.nightModeEnabled {
            textLabel?.textColor = UIColor.whiteColor()
            detailTextLabel?.textColor = UIColor.lightGrayColor()
            backgroundColor = UIColor.darkModeCellColor()
            selectedBackgroundView?.backgroundColor = UIColor.darkModeCellSelectionColor()
        } else {
            textLabel?.textColor = UIColor.blackColor()
            detailTextLabel?.textColor = UIColor.cellDetailTextColor()
            backgroundColor = UIColor.whiteColor()
            selectedBackgroundView?.backgroundColor = UIColor.cellSelectionColor()
        }
    }

}
