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
    
    static let sBFExecutor = BFExecutor { (block: @escaping () -> Void) in
        DispatchQueue.main.async(execute: block)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        parseClassName = "Photo"
        pullToRefreshEnabled = true;
        paginationEnabled = true;
        objectsPerPage = 25;
    }
    
    override func queryForCollection() -> PFQuery<PFObject> {
        print(">>>>>search")
        let query = PFQuery(className: parseClassName!)
        query.order(byDescending: "createdAt")
        query.whereKey("album", equalTo: album)
        return query
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, object: PFObject?) -> PFCollectionViewCell? {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PFCollectionViewCell
        cell.imageView.image = UIImage(named: "placeholder")
        
        if let imageFile = object?["thumbnail"] as? PFFile {
            cell.imageView.file = imageFile
            cell.imageView.loadInBackground()
        }
        
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonCamera.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        self.title = album["name"] as? String
        
    }
    
    @IBAction func takePicture(_ sender : Any) {
        pickImageFromSource(.camera)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoViewController" {
            let indexPath = self.collectionView?.indexPath(for: sender as! UICollectionViewCell)
            let controller = (segue.destination as! PhotoViewController)
            
            controller.objects = self.objects
            controller.index = indexPath!.row
            
        } else if segue.identifier == "NetworkSourceViewController" {
            let controller = (segue.destination as! NetworkSourceViewController)
            controller.album = album
        }
        
        super.prepare(for: segue, sender: sender)
    }
    
}


extension AlbumDetailController {
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout:UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 3
        return CGSize(width: width, height: width)
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
                let thumbnail = self.resizeImage(image: image, size: 200)
                let fullImage = self.resizeImage(image: image, size: 800)
                
                let thumbnailFile = PFFile(data: UIImageJPEGRepresentation(thumbnail, 0.75)!)!
                let fullImageFile = PFFile(data: UIImageJPEGRepresentation(fullImage, 0.75)!)!
                let photo = PFObject(className:"Photo")
                photo["album"] = self.album
                
                photo.saveEventually().continue(with: AlbumDetailController.sBFExecutor, with: { (result) -> Any? in
                    self.loadObjects()
                    
                    var tasks : [BFTask<AnyObject>] = []
                    tasks.append(thumbnailFile.saveInBackground() as! BFTask<AnyObject>)
                    tasks.append(fullImageFile.saveInBackground() as! BFTask<AnyObject>)
                    
                    return BFTask<AnyObject>(forCompletionOfAllTasksWithResults: tasks)
                    
                }).continue(with: AlbumDetailController.sBFExecutor, with: { (result) -> Any? in
                    photo["thumbnail"] = thumbnailFile
                    photo["fullImage"] = fullImageFile
                    return photo.saveEventually()
                    
                }).continue(with: AlbumDetailController.sBFExecutor, with: { (result) -> Any? in
                    self.loadObjects()
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
