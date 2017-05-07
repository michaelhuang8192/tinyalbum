//
//  ServerMonitor.swift
//  tinyalbum
//
//  Created by Michael Huang on 5/1/17.
//  Copyright © 2017 TinyAppsDev. All rights reserved.
//

import Foundation
import Parse

//not threadsafe
class ServerMonitor : NSObject {
    public static let CHECK_INTERVAL: Double = 3
    public static let shared = ServerMonitor()
    
    private var observers = [NSObject: (Bool) -> Void]()
    private var timer: Timer? = nil
    private var isReachable = true
    private var isRunning = false
    
    private override init() {
        super.init()
        
    }
    
    public func register(_ observer: NSObject, selector aSelector: @escaping (Bool) -> Void) {
        observers[observer] = aSelector
    }
    
    public func unregister(_ observer: NSObject) {
        observers.removeValue(forKey: observer)
    }
    
    public func unregisterAll() {
        observers.removeAll()
    }
    
    private func createTimer() -> Timer {
        return Timer.scheduledTimer(timeInterval: ServerMonitor.CHECK_INTERVAL, target: self, selector: #selector(self.onCheck), userInfo: nil, repeats: false)
    }
    
    public func start() {
        if isRunning { return }
        isRunning = true
        
        if timer == nil {
            timer = createTimer()
        }
    }
    
    public func stop() {
        if !isRunning { return }
        isRunning = false
        
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    public func onCheck() {
        timer = nil
        
        let req = URLRequest(url: URL(string: (Parse.currentConfiguration()?.server)!)!)
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            DispatchQueue.main.async {
                if !self.isRunning { return }
                
                let isReachable = (error == nil)
                if isReachable != self.isReachable {
                    self.isReachable = isReachable
                    //print("alert \(self.isReachable)")
                    for cb in self.observers {
                        cb.value(isReachable)
                    }
                }
                self.timer = self.createTimer()
            }
        }.resume()
        
    }
    
    
}
