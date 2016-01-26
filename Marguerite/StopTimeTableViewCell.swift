//
//  StopTimeTableViewCell.swift
//  Marguerite
//
//  Created by Andrew Finke on 7/1/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import UIKit

class StopTimeTableViewCell: UITableViewCell {

    /*
    Cell used in stop info table view for displaying route image and next departure time
    */
    
    @IBOutlet private weak var departureTimeLabel: UILabel!
    @IBOutlet private weak var routeImageView: UIImageView!
    @IBOutlet private weak var imageViewWidth: NSLayoutConstraint!
    
    var stopTime: ShuttleStopTime! {
        didSet {
            departureTimeLabel.text = stopTime.formattedTime
            routeImageView.image = stopTime.route.image
            imageViewWidth.constant = stopTime.route.image.size.width
            routeImageView.layoutIfNeeded()
        }
    }
    
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
            departureTimeLabel.textColor = UIColor.lightGrayColor()
            backgroundColor = UIColor.darkModeCellColor()
            selectedBackgroundView?.backgroundColor = UIColor.darkModeCellSelectionColor()
        } else {
            departureTimeLabel.textColor = UIColor.cellDetailTextColor()
            backgroundColor = UIColor.whiteColor()
            selectedBackgroundView?.backgroundColor = UIColor.cellSelectionColor()
        }
    }
}
