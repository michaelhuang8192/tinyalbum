//
//  HomeViewControllernbn.swift
//  tinyalbum
//
//  Created by pk on 4/8/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import CoreData

class HomeViewController: PFQueryTableViewController {
    
    var emptyLabel: UILabel!
    var searchBar: UISearchBar!
    var currentUser: PFUser!
    var currentTerm = ""
    var persistentContainer: NSPersistentContainer!
    var tableViewSepColor: UIColor!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        parseClassName = "Album"
        pullToRefreshEnabled = true
        paginationEnabled = true
        objectsPerPage = 25
        
        persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    override func queryForTable() -> PFQuery<PFObject> {
        var predicate : NSPredicate
        if PFUser.current() != nil {
            predicate = NSPredicate(format: "user=%@ or isPublic=true", PFUser.current()!)
        } else {
            predicate = NSPredicate(format: "isPublic=true")
        }
        
        let query = PFQuery(className: parseClassName!, predicate: predicate)
        query.order(by: [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: true)
        ])
        
        if !currentTerm.isEmpty {
            query.whereKey("name", contains: currentTerm)
        }
        
        query.cachePolicy = PFCachePolicy.cacheThenNetwork
        
        return query
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width:0, height:0))
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor.black
        emptyLabel.text = "No Album Yet"
        tableViewSepColor = tableView.separatorColor
        
        searchBar = UISearchBar()
        searchBar.placeholder = "Search something ..."
        searchBar.delegate = self
        
        navigationItem.titleView = searchBar
        
        hideKeyboardWhenTappedAround()
        
        currentUser = PFUser.current()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.current() == nil {
            clear()
        } else if PFUser.current() != currentUser {
            currentUser = PFUser.current()
            loadObjects()
        }
        
        checkLogin()
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        searchBar.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func checkLogin() {
        if PFUser.current() == nil {
            DispatchQueue.main.async {
                let signInViewController = SignInViewController()
                self.present(signInViewController, animated: true, completion: nil)
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = super.tableView(tableView, numberOfRowsInSection: section)
        
        if !isLoading && (objects == nil || objects?.count == 0) {
            tableView.separatorColor = UIColor.clear
            tableView.backgroundView = emptyLabel
        } else {
            tableView.separatorColor = tableViewSepColor
            tableView.backgroundView = nil
        }

        
        return num
    }

    @IBAction func addAlbum(_ sender: Any) {
        let vc = UIAlertController(title: "New Album", message: "Enter a new album name:", preferredStyle: .alert)
        vc.addTextField(configurationHandler: { textField -> Void in
            textField.placeholder = "Album Name"
        })
        vc.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        vc.addAction(UIAlertAction(title: "Create", style: .default, handler: { alertAction -> Void in
            if let textFields = vc.textFields, let albumName = textFields[0].text, !albumName.isEmpty {
                let album = PFObject(className:"Album")
                album["name"] = albumName
                album["user"] = PFUser.current()
                album["isPublic"] = false
                album.saveEventually({ (success, error) in
                    self.loadObjects();
                })
            }
        }))
        present(vc, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AlbumDetailController" {
            let album = self.object(at: self.tableView.indexPath(for: (sender as! PFTableViewCell)))
            let controller = (segue.destination as! AlbumDetailController)
            controller.album = album
        }
        
        super.prepare(for: segue, sender: sender)
    }

}

extension HomeViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, object: PFObject?) -> PFTableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell") as! PFTableViewCell
        cell.textLabel?.text = object!["name"] as? String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, let album = object(at: indexPath) {
            removeObject(at: indexPath)
            deleteAlbumPhotos(album: album)
        }
    }
    
    //delete network photos from local storage
    func deleteAlbumPhotos(album: PFObject) {
        let objectId = album.objectId
        self.persistentContainer.performBackgroundTask({ (context) in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NetworkPhoto.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "albumId = %@", argumentArray: [objectId!])
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            
            let _ = (try? context.execute(batchDeleteRequest)) as? NSBatchDeleteResult
        })
    }
    
}

extension HomeViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}

//handle search
extension HomeViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchWithTerm), object: nil)
        perform(#selector(self.searchWithTerm), with: nil, afterDelay: 0.5)
    }
    
    func searchWithTerm() {
        if let searchBar = self.searchBar, var term = searchBar.text {
            term = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if term == currentTerm { return }
            
            currentTerm = term
            loadObjects()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchWithTerm), object: nil)
        perform(#selector(self.searchWithTerm), with: nil)
    }
    
}
