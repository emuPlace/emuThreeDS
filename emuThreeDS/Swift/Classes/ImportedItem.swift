//
//  ImportedItem.swift
//  emuThreeDS
//
//  Created by Antique on 15/6/2023.
//

import Foundation
import UIKit

struct ImportedItem : Codable, Comparable, Hashable, Identifiable {
    var id = UUID()
    
    let path: String
    let publisher, region, size, title: String
    
    init(gameInfo: (String, String, String, String, String)) {
        self.path = gameInfo.0
        self.publisher = gameInfo.1
        self.region = gameInfo.2
        self.size = gameInfo.3
        self.title = gameInfo.4
    }
    
    
    func getIcon(for path: String) -> UIImage? {
        return Data(bytes: CitraWrapper.shared().getIcon(path: path), count: 48 * 48 * 8).decodeRGB565(width: 48, height: 48)
    }
    
    
    static func < (lhs: ImportedItem, rhs: ImportedItem) -> Bool {
        return lhs.title < rhs.title
    }
}
