//
//  LibraryManager.swift
//  emuThreeDS
//
//  Created by Antique on 20/6/2023.
//

import Accelerate
import Foundation
import UIKit

class LibraryManager {
    static let shared = LibraryManager()
    let citraWrapper = CitraWrapper.shared()
    
    
    func getImportedItemGameInformation(for path: String) -> (String, String, String, String, String) {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        
        var size: Int64 = 0
        do {
            size = try FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64 ?? 0
        } catch { print(error.localizedDescription) }
        
        
        return (path, citraWrapper.getPublisher(path: path), citraWrapper.getRegion(path: path), formatter.string(fromByteCount: size), citraWrapper.getTitle(path: path))
    }
    
    
    func getLibrary() -> [InstalledItem] {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        let directory = documentsDirectory.appendingPathComponent("roms", conformingTo: .directory)
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            } catch {
                print(error.localizedDescription)
                return []
            }
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".3ds") || $0.hasSuffix(".cci") || $0.hasSuffix(".cxi") }
            if contents.count == 0 {
                return []
            }
            
            return contents.reduce(into: [InstalledItem]()) { partialResult, file in
                let path = directory.appendingPathComponent(file, conformingTo: .fileURL).path
                
                let rom = InstalledItem(gameInfo: self.getImportedItemGameInformation(for: path))
                
                partialResult.append(rom)
            }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}
