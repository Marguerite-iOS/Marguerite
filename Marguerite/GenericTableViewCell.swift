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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme", name: UpdatedThemeNotification, object: nil)
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
            detailTextLabel?.textColor = UIColor(red: 142.0/255.0, green: 142.0/255.0, blue: 147.0/255.0, alpha: 1.0)
            backgroundColor = UIColor.whiteColor()
            selectedBackgroundView?.backgroundColor = UIColor(red: 216.75/255.0, green: 216.75/255.0, blue: 216.75/255.0, alpha: 1.0)
        }
    }

}
