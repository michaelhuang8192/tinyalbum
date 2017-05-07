//
//  NetworkSourceViewController.swift
//  tinyalbum
//
//  Created by Michael Huang on 4/16/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import UIKit
import Parse
import CoreData
import BoltsSwift

class NetworkSourceViewController : CoreDataCollectionViewController {
    
    var album: PFObject!
    var persistentContainer: NSPersistentContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        setupFetchRequest()
        
        let fr: NSFetchRequest<NSFetchRequestResult> = NetworkPhoto.fetchRequest()
        fr.predicate = NSPredicate(format: "albumId = %@", argumentArray: [album.objectId!])
        persistentContainer.performBackgroundTask { (context) in
            if let count = try? context.count(for: fr) {
                if count <= 0 {
                    DispatchQueue.main.async {
                        self.emptyLabel.text = "Loading..."
                    }
                    self.loadPhotoUrlsFromNetwork().continue(with: Utils.sMainBFExecutor, with: { (task) -> Any? in
                        self.emptyLabel.text = "No Photo Yet"
                    })
                }
            }
        }
        
    }
    
    func setupFetchRequest() {
        let fr: NSFetchRequest<NSFetchRequestResult>  = NetworkPhoto.fetchRequest()
        fr.sortDescriptors = [
            NSSortDescriptor(key: "photoUrl", ascending: true)
        ]
        fr.predicate = NSPredicate(format: "albumId = %@", argumentArray: [album.objectId!])
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fr,
            managedObjectContext: persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController!.object(at: indexPath) as! NetworkPhoto
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NetworkSourceCollectionCell", for: indexPath) as! NetworkSourceCollectionCell
        
        cell.indicator.stopAnimating()
        cell.label.isHidden = true
        if photo.thumbnailFile != nil {
            cell.imageView.image = UIImage(data: photo.thumbnailFile! as Data)
            if photo.photoId == "" {
                cell.indicator.isHidden = false
                cell.indicator.startAnimating()
            } else if photo.photoId != nil {
                cell.label.isHidden = false
            }
        } else {
            cell.imageView.image = UIImage(named: "placeholder")
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let networkPhoto = fetchedResultsController!.object(at: indexPath) as? NetworkPhoto {
            let thumbnailFileData = networkPhoto.thumbnailFile
            let imageFileData = networkPhoto.imageFile
            if thumbnailFileData == nil || imageFileData == nil { return }
            
            let objectId = networkPhoto.objectID
            if let photoId = networkPhoto.photoId {
                let query = PFQuery(className:"Photo")
                query.getObjectInBackground(withId: photoId).continue({ (result) -> Any in
                    if result.result != nil {
                        return photoId
                    } else {
                        return self.saveNetworkPhoto(
                            objectId: objectId,
                            thumbnailFileData: thumbnailFileData! as Data,
                            imageFileData: imageFileData! as Data
                        )
                    }
                })
                
            } else {
                let _ = saveNetworkPhoto(
                    objectId: objectId,
                    thumbnailFileData: thumbnailFileData! as Data,
                    imageFileData: imageFileData! as Data
                )
            }
        }
    }
    
    func saveNetworkPhoto(objectId: NSManagedObjectID, thumbnailFileData: Data, imageFileData: Data) -> BFTask<AnyObject> {
        let photo = PFObject(className:"Photo")
        photo["album"] = album
        
        let thumbnailFile = PFFile(data: thumbnailFileData)!
        let fullImageFile = PFFile(data: imageFileData)!
        
        let taskCompletionSource = BFTaskCompletionSource<AnyObject>()
        self.persistentContainer.performBackgroundTask({ (context) in
            if let networkPhoto = (try? context.existingObject(with: objectId)) as? NetworkPhoto {
                networkPhoto.photoId = ""
                try? context.save()
            }
            taskCompletionSource.setResult("" as AnyObject)
        })
        
        return taskCompletionSource.task.continue(successBlock: { (result) -> Any? in
            return photo.saveEventually()
            
        }).continue(successBlock: { (result) -> Any? in
            var tasks : [BFTask<AnyObject>] = []
            tasks.append(thumbnailFile.saveInBackground() as! BFTask<AnyObject>)
            tasks.append(fullImageFile.saveInBackground() as! BFTask<AnyObject>)
            
            return BFTask<AnyObject>(forCompletionOfAllTasksWithResults: tasks)
        }).continue(successBlock: { (result) -> Any? in
            photo["thumbnail"] = thumbnailFile
            photo["fullImage"] = fullImageFile
            
            return photo.saveEventually()
        }).continue(successBlock: { (result) -> Task<AnyObject> in
            
            DispatchQueue.main.async {
                UserDefaults.standard.set(true, forKey: "refreshAlbumDetailController")
            }
            
            let photoId = photo.objectId
            let taskCompletionSource = TaskCompletionSource<AnyObject>()
            
            self.persistentContainer.performBackgroundTask({ (context) in
                if let networkPhoto = (try? context.existingObject(with: objectId)) as? NetworkPhoto {
                    networkPhoto.photoId = photoId
                    try? context.save()
                }
                taskCompletionSource.set(result: photoId as AnyObject)
            })
            
            return taskCompletionSource.task
        })
        
    }
    
}


extension NetworkSourceViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout:UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 3
        return CGSize(width: width, height: width)
    }
}

extension NetworkSourceViewController {
    
    func loadPhotoUrlsFromNetwork() ->BFTask<AnyObject> {
        print("Loading Network Photos ...")
        
        let gss = GoogleSearchService.shared
        return gss.searchImages(term: album["name"] as! String).continue({ (result) -> Any? in
            if result.isCancelled { return nil }
            if result.error != nil {
                print("loadPhotoUrlsFromNetwork -> Error: \(result.error!)")
                return nil
            }
            
            var links = [String]()
            if let js = result.result as? [String: Any], let items = js["items"] as? [[String: Any]] {
                for item in items {
                    if let link = item["link"] as? String {
                        links.append(link)
                    }
                }
            }
            
            if links.count > 0 {
                self.saveAndFetchNetworkPhoto(links: links)
            }
            
            return nil
        })
        
    }
    
    func saveAndFetchNetworkPhoto(links: [String]) {
        
        persistentContainer.performBackgroundTask({ (context) in
            var photoList = [NetworkPhoto]()
            for link in links {
                let photo = NetworkPhoto(context: context)
                photo.photoUrl = link
                photo.albumId = self.album.objectId!
                photoList.append(photo)
            }
            
            try? context.save()
            
            var ctxs = [NSManagedObjectID]()
            for photo in photoList {
                ctxs.append(photo.objectID)
            }
            
            self.downloadPhotos(urls: links, ctxs: ctxs)
        })
        
    }
    
    func downloadPhotos(urls: [String], ctxs: [Any]) {
        PhotoDownloader.shared.download(urlList: urls, ctxList: ctxs) {data, ctx in
            let objectId = ctx as! NSManagedObjectID
            
            self.persistentContainer.performBackgroundTask({ (context) in
                let photo: NetworkPhoto! = (try? context.existingObject(with: objectId)) as? NetworkPhoto
                if photo == nil { return }
                
                if let data = data as NSData? {
                    if let image = UIImage(data: data as Data) {
                        let thumbnailImage = Utils.resizeImage(image: image, size: 200)
                        let resizedImage = Utils.resizeImage(image: image, size: 800)
                        photo.thumbnailFile = UIImageJPEGRepresentation(thumbnailImage, 0.75)! as NSData
                        photo.imageFile = UIImageJPEGRepresentation(resizedImage, 0.75)! as NSData
                    } else {
                        print("Can't Encode Image Data - \(String(describing: photo.photoUrl))")
                        context.delete(photo)
                    }
                    
                } else {
                    print("No Image Data - \(String(describing: photo.photoUrl))")
                    context.delete(photo)
                }
                
                try? context.save()
            })
        }
    }
    
}


