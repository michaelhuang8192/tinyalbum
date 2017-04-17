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

class HomeViewController: PFQueryTableViewController {
    
    var searchBar: UISearchBar!
    var currentUser: PFUser!
    var currentTerm = ""

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        parseClassName = "Album"
        pullToRefreshEnabled = true;
        paginationEnabled = true;
        objectsPerPage = 25;
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
            query.whereKey("name", hasPrefix: currentTerm)
        }
        
        return query
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                let loginViewController = PFLogInViewController()
                loginViewController.delegate = self
                loginViewController.signUpController!.delegate = self
                self.present(loginViewController, animated: true, completion: nil)
            }
        }
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
    
}

extension HomeViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}

extension HomeViewController : PFLogInViewControllerDelegate {
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        logInController.dismiss(animated: true, completion: nil)
    }
}

extension HomeViewController : PFSignUpViewControllerDelegate {
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        signUpController.dismiss(animated: true, completion: nil)
    }
}


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
            print("search: \(currentTerm)")
            loadObjects()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.searchWithTerm), object: nil)
        perform(#selector(self.searchWithTerm), with: nil)
    }
    
}
