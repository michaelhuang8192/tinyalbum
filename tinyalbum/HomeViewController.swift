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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        parseClassName = "Album"
        pullToRefreshEnabled = true;
        paginationEnabled = true;
        objectsPerPage = 25;
    }
    
    override func queryForTable() -> PFQuery<PFObject> {
        print(">>>>>search")
        let query = PFQuery(className: parseClassName!)
        query.order(byDescending: "createdAt")
        return query
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar = UISearchBar()
        searchBar.placeholder = "Search Any Thing"
        searchBar.delegate = self
        
        navigationItem.titleView = searchBar
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
                album["canRead"] = PFUser.current()
                album["photos"] = []
                
                album.saveEventually({ (success, error) in
                    print(">>>>\(album)")
                    self.loadObjects();
                })
            }
        }))
        present(vc, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AlbumDetail" {
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
        print(">>>>\(searchText)")
    }
    
}
