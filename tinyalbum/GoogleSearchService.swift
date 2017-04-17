//
//  GoogleSearchService.swift
//  tinyalbum
//
//  Created by Michael Huang on 4/16/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import Bolts

class GoogleSearchService : NSObject {
    
    enum Exception : Error {
        case InvalidData
    }
    
    static let API_URL = "https://www.googleapis.com/customsearch/v1"
    
    public static let shared = getInstance()
    
    var api: String!
    var cx: String!
    
    public static func getInstance() -> GoogleSearchService {
        let api = Bundle.main.object(forInfoDictionaryKey: "Google Custom Search API") as! String
        let cx = Bundle.main.object(forInfoDictionaryKey: "Google Custom Search ID") as! String
    
        return GoogleSearchService(api: api, cx: cx)
    }
    
    public init(api: String, cx: String) {
        self.api = api
        self.cx = cx
    }
    
    func newRequest(query: [String: Any]?) -> NSMutableURLRequest {
        let urlComponents = NSURLComponents(string: GoogleSearchService.API_URL)!
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "key", value: self.api))
        queryItems.append(URLQueryItem(name: "cx", value: self.cx))
        
        if let query = query {
            for (key, val) in query {
                queryItems.append(URLQueryItem(name: key, value: String(describing: val)))
            }
        }
        
        urlComponents.queryItems = queryItems
        return NSMutableURLRequest(url: urlComponents.url!)
    }
    
    func execRequest(request: NSMutableURLRequest) -> BFTask<AnyObject> {
        let taskCompletionSource = BFTaskCompletionSource<AnyObject>()
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if error != nil {
                taskCompletionSource.setError(error!)
            } else if data == nil {
                taskCompletionSource.setError(Exception.InvalidData)
            } else {
                do {
                    if let js = try JSONSerialization.jsonObject(with: data!) as? [String: Any] {
                        taskCompletionSource.setResult(js as AnyObject)
                    } else {
                        taskCompletionSource.setError(Exception.InvalidData)
                    }
                } catch {
                    taskCompletionSource.setError(error)
                }
            }
        }
        task.resume()
        
        return taskCompletionSource.task
    }

    func searchImages(term: String) -> BFTask<AnyObject> {
        let request = newRequest(query: [
            "q": term,
            "searchType": "image",
            "fileType": "jpg"
        ])
        
        return execRequest(request: request)
    }
    
}
