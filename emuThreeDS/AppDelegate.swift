//
//  AppDelegate.swift
//  emuThreeDS
//
//  Created by Antique on 14/6/2023.
//

import Darwin
import UIKit

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Converted from C to Swift, maybe incorrect
        let sym = dlsym(dlopen("/usr/lib/libsystemhook.dylib", RTLD_NOW), "jbdswDebugMe")
        if let sym {
            let function = unsafeBitCast(sym, to: (@convention(c)() -> Int64).self)
            let result = function()
            
            UserDefaults.standard.setValue(result, forKey: "dopamineJITResult")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
