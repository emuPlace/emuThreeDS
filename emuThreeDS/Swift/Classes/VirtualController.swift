//
//  VirtualController.swift
//  emuThreeDS
//
//  Created by Antique on 27/6/2023.
//

import Foundation
import UIKit

struct VirtualController : Codable, Hashable {
    struct Button : Codable, Hashable {
        struct Position : Codable, Hashable {
            let x, y: Int
        }
        
        struct Size : Codable, Hashable {
            let w, h: Int
        }
        
        
        let position: Position
        let size: Size
    }
    
    let buttons: [Button]
}
