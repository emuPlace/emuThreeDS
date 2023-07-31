//
//  SceneDelegate.swift
//  emuThreeDS
//
//  Created by Antique on 14/6/2023.
//

import SwiftUI
import UIKit

// more could go here for a "releases" screen
struct GitHubRelease : Codable, Comparable {
    static func < (lhs: GitHubRelease, rhs: GitHubRelease) -> Bool {
        return lhs.tag_name < rhs.tag_name
    }
    
    static func > (lhs: GitHubRelease, rhs: GitHubRelease) -> Bool {
        return lhs.tag_name > rhs.tag_name
    }
    
    let tag_name: String
}



class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var citraWrapper = CitraWrapper.shared()

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        window = UIWindow(windowScene: windowScene)
        guard let window = window else {
            return
        }
        
        window.rootViewController = PlaceholderViewController()
        
        Task {
            if try await checkIfNewerVersionExists() {
                BMACAuthenticate.shared.presentApplication(for: window)
            } else {
                if let email = UserDefaults.standard.string(forKey: "email") {
                    if try await BMACAuthenticate.shared.validate(for: email) {
                        BMACAuthenticate.shared.presentApplication(for: window)
                    } else {
                        window.rootViewController = AuthenticationViewController(.init(systemName: "lock.fill"), "Authenticate", "Authenticate with Buy Me A Coffee to proceed with testing.")
                    }
                } else {
                    window.rootViewController = AuthenticationViewController(.init(systemName: "lock.fill"), "Authenticate", "Authenticate with Buy Me A Coffee to proceed with testing.")
                }
            }
        }
        
        window.tintColor = .systemOrange
        window.makeKeyAndVisible()
    }
    
    
    fileprivate func checkIfNewerVersionExists() async throws -> Bool {
        guard let url = URL(string: "https://api.github.com/repos/emuplace/emuthreeds/releases") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode([GitHubRelease].self, from: data).sorted(by: >)
        
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let version = "\(shortVersion).\(buildVersion)"
        
        guard let first = decoded.first else {
            return false
        }
        
        return first.tag_name > version
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        citraWrapper.resume()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        citraWrapper.pause()
    }
}
