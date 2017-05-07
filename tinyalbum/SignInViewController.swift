//
//  SignInViewController.swift
//  tinyalbum
//
//  Created by Michael Huang on 5/6/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import ParseUI
import Parse

class SignInViewController : PFLogInViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logInView?.logo = UIImageView(image: UIImage(named: "photo-album"))
        self.delegate = self
        
        self.signUpController?.signUpView?.logo = UIImageView(image: UIImage(named: "photo-album"))
        self.signUpController?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if PFUser.current() != nil {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
}

extension SignInViewController : PFLogInViewControllerDelegate {
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        logInController.dismiss(animated: true, completion: nil)
    }
}

extension SignInViewController : PFSignUpViewControllerDelegate {
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        signUpController.dismiss(animated: true, completion: nil)
    }
}

