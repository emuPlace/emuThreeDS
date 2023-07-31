//
//  LibraryViewController.swift
//  emuThreeDS
//
//  Created by Antique on 15/6/2023.
//

import Foundation
import UIKit
import UniformTypeIdentifiers


class LibraryViewController : UICollectionViewController, ImportingProgressDelegate, UIDocumentPickerDelegate {
    var dataSource: UICollectionViewDiffableDataSource<String, AnyHashable>! = nil
    var snapshot: NSDiffableDataSourceSnapshot<String, AnyHashable>! = nil
    
    var citraWrapper = CitraWrapper.shared()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.setLeftBarButton(UIBarButtonItem(systemItem: .add, menu: UIMenu(children: [
            UIAction(title: "Convert CIA", image: UIImage(systemName: "arrow.triangle.2.circlepath.circle.fill"), handler: { action in
                
            }),
            UIAction(title: "Import CIAs", image: UIImage(systemName: "arrow.down.doc.fill"), handler: { action in
                self.openDocumentPicker()
            })
        ])), animated: true)
        title = "Library"
        view.backgroundColor = .systemBackground
        
        
        prepareAndDisplayLibrary()
        NotificationCenter.default.addObserver(self, selector: #selector(importingProgressDidFinish(notification:)), name: Notification.Name("importingProgressDidFinish"), object: nil)
        
        
        if dlsym(dlopen("/usr/lib/libsystemhook.dylib", RTLD_NOW), "jbdswDebugMe") != nil {
            let alertController = UIAlertController(title: "JIT", message: "Dopamine JIT result: \(UserDefaults.standard.string(forKey: "dopamineJITResult") ?? "N/A")", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alertController, animated: true)
        }
    }
    
    @objc func importingProgressDidFinish(notification: Notification) {
        guard let fileURL = notification.object as? URL else {
            return
        }
        
        snapshot.appendItems([ImportedItem(gameInfo: LibraryManager.shared.getImportedItemGameInformation(for: fileURL.path))], toSection: "Imported")
        if #available(iOS 15, *) {
            Task {
                await dataSource.apply(snapshot)
            }
        } else {
            dataSource.apply(snapshot)
        }
    }
    
    
    fileprivate func openDocumentPicker() {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType("com.nintendo-3ds.cia")!
        ], asCopy: true)
        documentPickerViewController.allowsMultipleSelection = true
        documentPickerViewController.delegate = self
        present(documentPickerViewController, animated: true)
    }
    
    
    // MARK: ImportingProgressDelegate
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    func importingProgressDidChange(_ url: URL, received: CGFloat, total: CGFloat) {
        if (received / total) >= 0.9 {
            impactFeedbackGenerator.impactOccurred()
        }
    }
    
    
    // MARK: UIDocumentPickerDelegate
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        citraWrapper.importCIAs(urls: urls)
    }
}



// MARK: LibraryViewControllerExtension
extension LibraryViewController {
    func prepareAndDisplayLibrary() {
        let importedItemCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ImportedItem> { cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.subtitleCell()
            contentConfiguration.image = itemIdentifier.getIcon(for: itemIdentifier.path)
            contentConfiguration.imageProperties.maximumSize = .init(width: 40, height: 40)
            contentConfiguration.imageProperties.cornerRadius = 8
            
            contentConfiguration.text = itemIdentifier.title
            contentConfiguration.textProperties.color = .label
            contentConfiguration.textProperties.numberOfLines = 1
            
            contentConfiguration.secondaryText = "\(itemIdentifier.region), \(itemIdentifier.publisher)"
            contentConfiguration.secondaryTextProperties.color = .secondaryLabel
            contentConfiguration.secondaryTextProperties.numberOfLines = 1
            cell.contentConfiguration = contentConfiguration
            
            cell.accessories = [
                UICellAccessory.label(text: itemIdentifier.size, options: .init(tintColor: .systemBlue))
            ]
        }
        
        let installedItemCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, InstalledItem> { cell, indexPath, itemIdentifier in
            var contentConfiguration = UIListContentConfiguration.subtitleCell()
            contentConfiguration.image = itemIdentifier.getIcon(for: itemIdentifier.path)
            contentConfiguration.imageProperties.maximumSize = .init(width: 40, height: 40)
            contentConfiguration.imageProperties.cornerRadius = 8
            
            contentConfiguration.text = itemIdentifier.title
            contentConfiguration.textProperties.color = .label
            contentConfiguration.textProperties.numberOfLines = 1
            
            contentConfiguration.secondaryText = "\(itemIdentifier.region), \(itemIdentifier.publisher)"
            contentConfiguration.secondaryTextProperties.color = .secondaryLabel
            contentConfiguration.secondaryTextProperties.numberOfLines = 1
            cell.contentConfiguration = contentConfiguration
            
            cell.accessories = [
                UICellAccessory.label(text: itemIdentifier.size, options: .init(tintColor: .systemBlue))
            ]
        }
        
        let supplementaryRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
            var contentConfiguration: UIListContentConfiguration
            if #available(iOS 15, *) {
               contentConfiguration = UIListContentConfiguration.extraProminentInsetGroupedHeader()
                contentConfiguration.text = self.dataSource.sectionIdentifier(for: indexPath.section) ?? "Invalid Section"
            } else {
               contentConfiguration = UIListContentConfiguration.groupedHeader()
                contentConfiguration.text = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            }
            
            supplementaryView.contentConfiguration = contentConfiguration
        }
        
        dataSource = UICollectionViewDiffableDataSource<String, AnyHashable>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            switch (itemIdentifier) {
            case let importedItem as ImportedItem:
                return collectionView.dequeueConfiguredReusableCell(using: importedItemCellRegistration, for: indexPath, item: importedItem)
            case let installedItem as InstalledItem:
                return collectionView.dequeueConfiguredReusableCell(using: installedItemCellRegistration, for: indexPath, item: installedItem)
            default:
                return nil
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryRegistration, for: indexPath)
        }
        
        
        snapshot = NSDiffableDataSourceSnapshot()
        snapshot.appendSections(["Imported", "Installed"])
        snapshot.appendItems(citraWrapper.importedCIAs().reduce(into: [ImportedItem](), { partialResult, filePath in
            partialResult.append(ImportedItem(gameInfo: LibraryManager.shared.getImportedItemGameInformation(for: filePath)))
        }), toSection: "Imported")
        snapshot.appendItems(LibraryManager.shared.getLibrary(), toSection: "Installed")
        if #available(iOS 15, *) {
            Task {
                await dataSource.apply(snapshot)
            }
        } else {
            dataSource.apply(snapshot)
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider:  { elements in
            UIMenu(children: [
                UIMenu(title: "Cheats", image: UIImage(systemName: "doc"), children: [
                    UIAction(title: "Add", image: UIImage(systemName: "plus"), handler: { action in
                        
                    }),
                    UIAction(title: "Remove", image: UIImage(systemName: "minus"), handler: { action in
                        
                    }),
                    UIAction(title: "Update", image: UIImage(systemName: "arrow.up"), handler: { action in
                        
                    })
                ]),
                UIMenu(title: "States", image: UIImage(systemName: "square.on.square"), children: [
                    UIAction(title: "Load", image: UIImage(systemName: "square.and.arrow.up"), handler: { action in
                        self.romFromIndexPath(indexPath: indexPath)
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .medium
                        
                        let alertController = UIAlertController(title: "Save States", message: "Select a save state to load before running the game.", preferredStyle: .actionSheet)
                        let saveStates = self.citraWrapper.saveStates()
                        saveStates.forEach { saveState in
                            alertController.addAction(UIAlertAction(title: dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(saveState.time))), style: .default, handler: { _ in
                                self.citraWrapper.loadState(saveStates.firstIndex(of: saveState)!)
                                
                                let emulationViewController = EmulationViewController()
                                emulationViewController.modalPresentationStyle = .overFullScreen
                                self.present(emulationViewController, animated: true)
                            }))
                        }
                        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        self.present(alertController, animated: true)
                    })
                ])
            ])
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        romFromIndexPath(indexPath: indexPath)
        
        let emulationViewController = EmulationViewController()
        emulationViewController.modalPresentationStyle = .overFullScreen
        present(emulationViewController, animated: true)
    }
    
    
    fileprivate func romFromIndexPath(indexPath: IndexPath) {
        if #available(iOS 15, *) {
            guard let sectionName = dataSource.sectionIdentifier(for: indexPath.section) else {
                return
            }
            
            let itemIdentifiers = dataSource.snapshot().itemIdentifiers(inSection: sectionName)
            switch (sectionName) {
            case "Imported":
                citraWrapper.insert(path: (itemIdentifiers[indexPath.row] as! ImportedItem).path)
                break
            case "Installed":
                citraWrapper.insert(path: (itemIdentifiers[indexPath.row] as! InstalledItem).path)
                break
            default:
                break
            }
        } else {
            let sectionName = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            let itemIdentifiers = dataSource.snapshot().itemIdentifiers(inSection: sectionName)
            switch (sectionName) {
            case "Imported":
                citraWrapper.insert(path: (itemIdentifiers[indexPath.row] as! ImportedItem).path)
                break
            case "Installed":
                citraWrapper.insert(path: (itemIdentifiers[indexPath.row] as! InstalledItem).path)
                break
            default:
                break
            }
        }
    }
}
