//
//  AlbumDetailController.swift
//  tinyalbum
//
//  Created by pk on 4/12/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import UIKit
import Parse
import ParseUI

class AlbumDetailController : PFQueryCollectionViewController {
    
    @IBOutlet weak var buttonCamera : UIBarButtonItem!
    
    var album : PFObject!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonCamera.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        self.title = album["name"] as! String
    }
    
    @IBAction func takePicture(_ sender : Any) {
        pickImageFromSource(.camera)
    }
    
}

extension AlbumDetailController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func pickImageFromSource(_ source: UIImagePickerControllerSourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = source
        present(pickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            DispatchQueue.main.async {
                let thumbnail = self.resizeImage(image: image, size: 200.0)
                let fullImage = self.resizeImage(image: image, size: 1000.0)
                
                let thumbnailFile = PFFile(data: UIImagePNGRepresentation(thumbnail)!)
                let fullImageFile = PFFile(data: UIImagePNGRepresentation(fullImage)!)
                
                thumbnailFile?.saveInBackground().continue({ (result) -> Any? in
                    return fullImageFile?.saveInBackground()
                    
                }).continue({ (result) -> Any? in
                    print(">>>>ok")
                    self.album["photo"] = [["thumbnail": thumbnailFile, "fullImage": fullImageFile]]
                    return self.album.saveInBackground()
                    
                }).continue({ (result) -> Any? in
                    
                    return nil
                })
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, size: CGFloat) -> UIImage {
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
