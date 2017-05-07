//
//  CoreDataCollectionViewController.swift
//
//
//  Created by Fernando Rodríguez Romero on 22/02/16.
//  Copyright © 2016 udacity.com. All rights reserved.
//

import UIKit
import CoreData


class CoreDataCollectionViewController: UICollectionViewController {
    
    var emptyLabel: UILabel!
    var _fcChanges = [[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width:0, height:0))
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor.black
        emptyLabel.text = "No Photo Yet"
    }
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                } catch let e as NSError {
                    print("Error while trying to perform a search: \(e)")
                }
            }
            collectionView?.reloadData()
        }
    }
    
}

extension CoreDataCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        if let fc = fetchedResultsController {
            count = fc.sections![section].numberOfObjects
        }
        
        if count <= 0 {
            emptyLabel.frame.size = collectionView.bounds.size
            collectionView.backgroundView = emptyLabel
        } else {
            collectionView.backgroundView = nil
        }
        
        return count
    }
    
}

//record all changes, update everything in a batch
extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self._fcChanges.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        _fcChanges.append([0, type, IndexSet(integer: sectionIndex)])
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        _fcChanges.append([1, type, indexPath as Any, newIndexPath as Any])
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView?.performBatchUpdates({
            guard let collectionView = self.collectionView else {
                return
            }
            
            for chg in self._fcChanges {
                if chg[0] as! Int == 0 {
                    switch (chg[1] as! NSFetchedResultsChangeType) {
                    case .insert:
                        collectionView.insertSections(chg[2] as! IndexSet)
                    case .delete:
                        collectionView.deleteSections(chg[2] as! IndexSet)
                    default:
                        break
                    }
                } else {
                    switch(chg[1] as! NSFetchedResultsChangeType) {
                    case .insert:
                        collectionView.insertItems(at: [chg[3] as! IndexPath])
                    case .delete:
                        collectionView.deleteItems(at: [chg[2] as! IndexPath])
                    case .update:
                        collectionView.reloadItems(at: [chg[2] as! IndexPath])
                    case .move:
                        collectionView.deleteItems(at: [chg[2] as! IndexPath])
                        collectionView.insertItems(at: [chg[3] as! IndexPath])
                    }
                }
            }
            
        }, completion: { (_) in
            
        })
        
    }
    
}

