//
//  StopTimeTableViewCell.swift
//  StanfordBus
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
            if let departureTimeString = stopTime.formattedTime {
                departureTimeLabel.text = departureTimeString
            }
            if let route = stopTime.route {
                routeImageView.image = route.image
                imageViewWidth.constant = route.image.size.width
                routeImageView.layoutIfNeeded()
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
            departureTimeLabel.textColor = UIColor.lightGrayColor()
            backgroundColor = UIColor.darkModeCellColor()
            selectedBackgroundView.backgroundColor = UIColor.darkModeCellSelectionColor()
        } else {
            departureTimeLabel.textColor = UIColor(red: 142.0/255.0, green: 142.0/255.0, blue: 147.0/255.0, alpha: 1.0)
            backgroundColor = UIColor.whiteColor()
            selectedBackgroundView.backgroundColor = UIColor(red: 216.75/255.0, green: 216.75/255.0, blue: 216.75/255.0, alpha: 1.0)
        }
    }
}
