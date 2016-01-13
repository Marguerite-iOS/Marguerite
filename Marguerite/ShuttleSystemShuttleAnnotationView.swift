//
//  ShuttleSystemShuttleAnnotationView.swift
//  Marguerite
//
//  Created by Andrew Finke on 7/7/15.
//  Copyright © 2015 Andrew Finke. All rights reserved.
//

import MapKit

class ShuttleSystemShuttleAnnotationView: MKAnnotationView {

    private var indicatorImageView: UIImageView!
    private var bubbleImageView: UIImageView!
    private var route: ShuttleRoute!
    
    // MARK: - Initializers
    
    init?(annotation: ShuttleSystemAnnotation) {
        super.init(annotation: annotation, reuseIdentifier: arc4random().description)
        guard let shuttle = annotation.object as? Shuttle, image = UIImage(named: "ShuttleIndicator") else {
            return nil
        }
        route = shuttle.route
        // Indicator down image from route bubble to spot on the map
        indicatorImageView = UIImageView(image: image)
        indicatorImageView.tintColor = route.routeColor
        addSubview(indicatorImageView)
        // The image that has the actual route name
        bubbleImageView = UIImageView(image: route.image)
        addSubview(bubbleImageView)
        bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        // Contraints
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: bubbleImageView, attribute: .CenterX, relatedBy: .Equal, toItem: indicatorImageView, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: bubbleImageView, attribute: .CenterY, relatedBy: .Equal, toItem: indicatorImageView, attribute: .Top, multiplier: 1.0, constant: -5.0))
        addConstraints(constraints)
        frame = CGRectMake(0, 0, bubbleImageView.frame.width, bubbleImageView.frame.height + indicatorImageView.frame.height)
        indicatorImageView.center = CGPointMake(bubbleImageView.frame.width / 2.0, indicatorImageView.frame.height + bubbleImageView.frame.height / 2.0)
        centerOffset = CGPointMake(0, -indicatorImageView.frame.height)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
