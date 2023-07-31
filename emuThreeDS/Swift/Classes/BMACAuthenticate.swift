//
//  BMACAuthenticate.swift
//  emuThreeDS
//
//  Created by Antique on 28/7/2023.
//

import Foundation
import SwiftUI
import UIKit

class BMACAuthenticate {
    static let shared = BMACAuthenticate()
    
    func validate(for email: String) async throws -> Bool {
        guard let url = URL(string: "https://developers.buymeacoffee.com/api/v1/subscriptions?status=active") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI5MTI5ZDIwMC1kYTdkLTRjY2MtOWQzZC01ODA0MTU0ZTgyMjYiLCJqdGkiOiI3YWIwMTg2YTNiNWJiNTExNDVmMTJmY2MzMTFhZGNhNjFhYTVmMTFiMGM3ODVmOTczNzUzZDYxYmQ3M2ZlMzhhMjUwYzI3NmVjNjQ2NDY2YiIsImlhdCI6MTY5MDUyOTc3OSwibmJmIjoxNjkwNTI5Nzc5LCJleHAiOjE3MDY0MjczNzksInN1YiI6IjIzOTM4MTMiLCJzY29wZXMiOlsicmVhZC1vbmx5Il19.pe0bApF4ErCoJj_u7FgUAPPa2Cug-jO2QpE-1ef7XQW8gUsGJFQ83g7l1L2deh8pRZz-hdqjSGD_J8kYygkWYkAaHRXcx-y_tfTZkrDI9YGUe_vDFK-BFaW-ZCPJ-68zquCblM_84ec5awCxvk0-z7iKFjQL7Y6AewCdRnf8Of0AN02DDxhn0rgbyyxQIZzFkIMtkdpzft6khAVpwKXTDp4llvJHoUzwFNR3jSe6Z0M__vRtsn6ZPT0oFJ7mmHzMnULexjwXe5BfYPGMqwJH5322teWeD00drVxgAVwBbRowaquBw9qbcXTnlx4SGVIk7ClerXURt9IxzQJOjTgENXvnlNcaPzCnfCRxUYmqXiPRdqjwvhATfVfF1TACHW5z3WPIwLdVh_-yrx1PfVLD4X8CRiE6wj5fazyk51gvoRfPrzmlQ7ezIsJO7A3ZBXPJA9TAhYBThwSmOrygdgf_CtutyUt4d9G-b25gQVE7q6iVt3g_YMaGA9bYbrWC6Yi-SVC2s_c00IE9u9-shkGIUoiuz3FGBWAhPk3Kql09gW0rQqos9oSLWLzVEgZ5-x06cIvz4Dj4SAfb1HYjbHFJUWhZB1G4g2jPs6l9Ver0DxowdoG4VVip100dnfZ_2c-1lLVkXSD80cL9YMfZVc0JkmVswKwLgm4LvVeAvVjTHTA", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        
        return decoded.data.contains(where: { $0.payer_email.lowercased() == email.lowercased() })
    }
    
    func presentApplication(for window: UIWindow) {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        
        let libraryViewController = LibraryViewController(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration))
        let libraryNavigationController = UINavigationController(rootViewController: libraryViewController)
        libraryViewController.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "books.vertical.fill"), tag: 0)
        
        let settingsViewController = UIHostingController(rootView: SettingsView())
        settingsViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: 1)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [libraryNavigationController, settingsViewController]
        
        tabBarController.modalPresentationStyle = .fullScreen
        window.rootViewController?.present(tabBarController, animated: true)
    }
}
