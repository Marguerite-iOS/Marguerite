//
//  StopTableViewCell.swift
//  Marguerite
//
//  Created by Andrew Finke on 6/30/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class StopTableViewCell: UITableViewCell  {
    
    /*
    Cell used in main stops table view for displaying stop name and all route images
    */
    
    @IBOutlet private weak var stopNameLabel: UILabel!
    @IBOutlet private weak var routesImageView: UIImageView!
    
    var stop: ShuttleStop? {
        didSet {
            if let stop = stop {
                routesImageView.image =  stop.routeBubblesImage
                stopNameLabel.text = stop.name
            }
        }
    }
    
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
            stopNameLabel.textColor = UIColor.whiteColor()
            selectedBackgroundView?.backgroundColor = UIColor.darkModeCellSelectionColor()
        } else {
            stopNameLabel.textColor = UIColor.blackColor()
            selectedBackgroundView?.backgroundColor = UIColor(red: 216.75/255.0, green: 216.75/255.0, blue: 216.75/255.0, alpha: 1.0)
        }
    }
}
