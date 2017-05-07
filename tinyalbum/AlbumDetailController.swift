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
    
    var emptyLabel: UILabel!
    @IBOutlet weak var buttonCamera : UIBarButtonItem!
    @IBOutlet weak var buttonDeleteModeSwitch: UIBarButtonItem!
    
    var album : PFObject!
    var inDeleteMode = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        parseClassName = "Photo"
        pullToRefreshEnabled = true;
        paginationEnabled = true;
        objectsPerPage = 25;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.bool(forKey: "refreshAlbumDetailController") {
            UserDefaults.standard.set(false, forKey: "refreshAlbumDetailController")
            
            loadObjects()
        }
    }
    
    override func queryForCollection() -> PFQuery<PFObject> {
        let query = PFQuery(className: parseClassName!)
        query.order(byDescending: "createdAt")
        query.whereKey("album", equalTo: album)
        query.cachePolicy = PFCachePolicy.cacheThenNetwork
        return query
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "PhotoViewController" && inDeleteMode {
            return false
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonCamera.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        self.title = album["name"] as? String
        
        emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width:0, height:0))
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor.black
        emptyLabel.text = "No Photo Yet"
        
    }
    
    @IBAction func takePicture(_ sender : Any) {
        pickImageFromSource(.camera)
    }
    
    @IBAction func switchDeleteMode(_ sender : Any) {
        if inDeleteMode {
            inDeleteMode = false
            buttonDeleteModeSwitch.tintColor = self.view.tintColor
        } else {
            inDeleteMode = true
            buttonDeleteModeSwitch.tintColor = UIColor.red
        }
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if inDeleteMode {
            if let photo = object(at: indexPath) {
                photo.deleteEventually().continue(with: Utils.sMainBFExecutor, with: { (result) -> Any? in
                    self.loadObjects()
                })
            }
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = super.collectionView(collectionView, numberOfItemsInSection: section)
        
        if count <= 0 && !isLoading {
            emptyLabel.frame.size = collectionView.bounds.size
            collectionView.backgroundView = emptyLabel
        } else {
            collectionView.backgroundView = nil
        }
        
        return count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, object: PFObject?) -> PFCollectionViewCell? {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PFCollectionViewCell
        //cell.imageView.contentMode = .scaleAspectFit
        cell.imageView.image = UIImage(named: "placeholder")
        
        if let imageFile = object?["thumbnail"] as? PFFile {
            cell.imageView.file = imageFile
            cell.imageView.loadInBackground()
        }
        
        return cell
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
            
            DispatchQueue.global().async {
                let thumbnail = Utils.resizeImage(image: image, size: 200)
                let fullImage = Utils.resizeImage(image: image, size: 800)
                
                let thumbnailFile = PFFile(data: UIImageJPEGRepresentation(thumbnail, 0.75)!)!
                let fullImageFile = PFFile(data: UIImageJPEGRepresentation(fullImage, 0.75)!)!
                let photo = PFObject(className:"Photo")
                photo["album"] = self.album
                
                photo.saveEventually().continue(with: Utils.sMainBFExecutor, with: { (result) -> Any? in
                    self.loadObjects()
                    
                    var tasks : [BFTask<AnyObject>] = []
                    tasks.append(thumbnailFile.saveInBackground() as! BFTask<AnyObject>)
                    tasks.append(fullImageFile.saveInBackground() as! BFTask<AnyObject>)
                    
                    return BFTask<AnyObject>(forCompletionOfAllTasksWithResults: tasks)
                    
                }).continue(successBlock: { (result) -> Any? in
                    photo["thumbnail"] = thumbnailFile
                    photo["fullImage"] = fullImageFile
                    return photo.saveEventually()
                    
                }).continue(with: Utils.sMainBFExecutor, with: { (result) -> Any? in
                    self.loadObjects()
                    
                })
                
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
}
