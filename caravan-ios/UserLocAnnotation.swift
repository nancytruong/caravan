//
//  File.swift
//  caravan-ios
//
//  Created by Sara Edmonds on 6/13/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

// MGLAnnotation protocol reimplementation
class UserLocAnnotation: NSObject, MGLAnnotation {
    
    // As a reimplementation of the MGLAnnotation protocol, we have to add mutable coordinate and (sub)title properties ourselves.
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    // Custom properties that we will use to customize the annotation's image.
    var image: UIImage?
    var reuseIdentifier: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
        self.image = dot(size: 15)
        self.reuseIdentifier = "userLocAnnotation"
    }
    
    func dot(size: Int) -> UIImage {
        let floatSize = CGFloat(size)
        let rect = CGRect(x: 0, y: 0, width: floatSize, height: floatSize)
        let strokeWidth: CGFloat = 1
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        
        let ovalPath = UIBezierPath(ovalIn: rect.insetBy(dx: strokeWidth, dy: strokeWidth))
        UIColor.lightGray.setFill()
        ovalPath.fill()
        
        UIColor.white.setStroke()
        ovalPath.lineWidth = strokeWidth
        ovalPath.stroke()
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}
