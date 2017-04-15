//
//  SettingsViewController.swift
//  tinyalbum
//
//  Created by pk on 4/9/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import UIKit
import Parse
import ParseUI

class SettingsViewController: UIViewController {
    
    @IBAction func logMeOut(_ sender: Any) {
        PFUser.logOut()
        
        self.navigationController?.popToRootViewController(animated: true);
    }
    
}
