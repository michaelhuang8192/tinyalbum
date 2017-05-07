//
//  AppDelegate.swift
//  tinyalbum
//
//  Created by pk on 4/8/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import UIKit
import CoreData
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var isConnectionAlertUp = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //setup Parse Server
        Parse.enableLocalDatastore()
        let serverInfo = Bundle.main.object(forInfoDictionaryKey: "TinyAlbumServer") as! [String:String]
        let config = ParseClientConfiguration {
            $0.applicationId = serverInfo["appId"]
            $0.server = serverInfo["url"]!
        }
        Parse.initialize(with: config)
        
        //register network monitor
        ServerMonitor.shared.register(self) { (isReachable) in
            
            if !isReachable, !self.isConnectionAlertUp, let controller = self.window?.rootViewController {
                self.isConnectionAlertUp = true
                let alert = UIAlertController(title: "Connection", message: "Can't connect to the server", preferredStyle:.alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (UIAlertAction) in
                   self.isConnectionAlertUp = false
                }))
                controller.present(alert, animated: true, completion: nil)
            }
            
        }
        ServerMonitor.shared.start()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        ServerMonitor.shared.stop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        ServerMonitor.shared.start()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ServerMonitor.shared.unregisterAll()
        self.saveContext()
    }

    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "tinyalbum")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

