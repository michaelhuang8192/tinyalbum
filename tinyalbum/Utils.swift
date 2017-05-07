//
//  Utils.swift
//  tinyalbum
//
//  Created by Michael Huang on 4/22/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import UIKit
import Bolts




class Utils {
    
    public static let sMainBFExecutor = BFExecutor { (block: @escaping () -> Void) in
        DispatchQueue.main.async(execute: block)
    }
    
    public static func resizeImage(image: UIImage, size: CGFloat) -> UIImage {
        var newSize: CGSize
        if(image.size.width > image.size.height) {
            newSize = CGSize(width: size, height: size / image.size.width * image.size.height)
        } else {
            newSize = CGSize(width: size / image.size.height * image.size.width, height: size)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
