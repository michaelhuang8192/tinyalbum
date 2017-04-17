//
//  PhotoViewController.swift
//  tinyalbum
//
//  Created by Michael Huang on 4/15/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import UIKit
import Parse
import ParseUI

class PhotoViewController : UIViewController {
    
    @IBOutlet weak var imageView : PFImageView!
    
    var objects: [PFObject]!
    var index: Int!
    var bfTask: BFTask<AnyObject>!
    
    static let sBFExecutor = BFExecutor { (block: @escaping () -> Void) in
        DispatchQueue.main.async(execute: block)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        leftSwipeGesture.direction = .left
        view.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        rightSwipeGesture.direction = .right
        view.addGestureRecognizer(rightSwipeGesture)
        
        loadImage()
    }
    
    func loadImage() {
        if let objects = self.objects, let index = self.index {
            let object = objects[index]
            if index < objects.count, let fullImage = object["fullImage"] as? PFFile, let thumbnail = object["thumbnail"] as? PFFile {
                if imageView.file == fullImage { return }
                
                imageView.image = UIImage(named: "placeholder")
                imageView.file = fullImage
                
                thumbnail.getDataInBackground(block: { (data, error) in
                    if fullImage != self.imageView.file { return }
                    
                    if data != nil && error != nil {
                        self.imageView.image = UIImage(data: data!)
                    }
                    
                    self.imageView.loadInBackground()
                })
                
            }
        }
    }
    
    func onTap() {
        dismiss(animated: true, completion: nil)
    }
    
    func onSwipe(_ recognizer : UISwipeGestureRecognizer) {
        if objects.count <= 0 { return }
        
        if recognizer.direction == .left {
            index = (index - 1 + objects.count) % objects.count
            loadImage()
        } else if recognizer.direction == .right {
            index = (index + 1) % objects.count
            loadImage()
        }
        
    }
}
