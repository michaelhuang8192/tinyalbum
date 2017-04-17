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

class NetworkSourceViewController : UICollectionViewController {
    
    var album: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPhotoUrlsFromNetwork()
    }
    
    func loadPhotoUrlsFromNetwork() {
        let gss = GoogleSearchService.shared
        gss.searchImages(term: album["name"] as! String).continue({ (result) -> Any? in
            if result.isCancelled { return nil }
            if result.error != nil {
                print("loadPhotoUrlsFromNetwork -> Error: \(result.error!)")
                return nil
            }
            
            if let js = result.result as? [String: Any], let items = js["items"] as? [[String: Any]] {
                for item in items {
                    print("\(item)")
                }
            }
            
            return nil
        })
        
    }
    
    
}
