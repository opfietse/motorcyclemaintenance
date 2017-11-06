//
//  CDMigration.swift
//  Groceries
//
//  Created by Tim Roadley on 30/09/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import UIKit
import CoreData

private let _sharedCDMigration = CDMigration()
class CDMigration: NSObject {
   
    // MARK: - SHARED INSTANCE
    class var shared : CDMigration {
        return _sharedCDMigration
    }
    
    // MARK: - SUPPORTING FUNCTIONS
    func storeExistsAtPath(storeURL:NSURL) -> Bool {
        if let _storePath = storeURL.path {
            if FileManager.default.fileExists(atPath: _storePath) {
                return true
            }
        } else {print("\(#function) FAILED to get store path")}
        return false
    }
    
    func store(storeURL:NSURL, isCompatibleWithModel model:NSManagedObjectModel) -> Bool {
        if self.storeExistsAtPath(storeURL: storeURL) == false {
            return true // prevent migration of a store that does not exist
        }

        do {    
            var _metadata:[String : AnyObject]?
            _metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL as URL, options: nil) as [String : AnyObject]
            if let metadata = _metadata {
                if model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            
                    print("The store is compatible with the current version of the model")
                    return true
                }
            } else {print("\(#function) FAILED to get metadata")}
        } catch {
            print("ERROR getting metadata from \(storeURL) \(error)")
        }

        print("The store is NOT compatible with the current version of the model")
        return false
    }

    func replaceStore(oldStore:NSURL, newStore:NSURL) throws {
        let manager = FileManager.default
        
        do {
            try manager.removeItemAtURL(oldStore as URL)
            try manager.moveItemAtURL(newStore, toURL: oldStore)
        }
    }
    
    // MARK: - PROGRESS REPORTING
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutableRawPointer) {
        
        if object is NSMigrationManager, let manager = object as? NSMigrationManager {
            
            if let notification = keyPath {
                NotificationCenter.defaultCenter.postNotificationName(notification, object: NSNumber(float: manager.migrationProgress))
            }
        } else {print("observeValueForKeyPath did not receive a NSMigrationManager class")}
    }

    // MARK: - MIGRATION
    func migrateStore(store:NSURL, sourceModel:NSManagedObjectModel, destinationModel:NSManagedObjectModel) {
        if let tempdir = store.deletingLastPathComponent {
            let tempStore = tempdir.URLByAppendingPathComponent("Temp.sqlite")
            let mappingModel = NSMappingModel(fromBundles: nil, forSourceModel: sourceModel, destinationModel: destinationModel)
            let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
            migrationManager.addObserver(self, forKeyPath: "migrationProgress", options: NSKeyValueObservingOptions.New, context: nil)

            do {
                try migrationManager.migrateStoreFromURL(store, type: NSSQLiteStoreType, options: nil, withMappingModel: mappingModel, toDestinationURL: tempStore, destinationType: NSSQLiteStoreType, destinationOptions: nil)
                try replaceStore(store, newStore: tempStore)
                    
                print("SUCCESSFULLY MIGRATED \(store) to the Current Model")
                    
            } catch {
                print("FAILED MIGRATION: \(error)")
            }
            migrationManager.removeObserver(self, forKeyPath: "migrationProgress")
        } else {print("\(#function) FAILED to prepare temporary directory")}
    }

    func migrateStoreWithProgressUI(store:NSURL, sourceModel:NSManagedObjectModel, destinationModel:NSManagedObjectModel) {
        // Show migration progress view preventing the user from using the app
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let initialVC = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            if let migrationVC = storyboard.instantiateViewController(withIdentifier: "migration") as? MigrationVC {
            
                initialVC.present(migrationVC, animated: false, completion: {
                    dispatch_async(dispatch_get_global_queue(DispatchQueue.GlobalQueuePriority.background, 0), {
                        print("BACKGROUND Migration started...")
                        self.migrateStore(store, sourceModel: sourceModel, destinationModel: destinationModel)
                        dispatch_async(dispatch_get_main_queue(), {
            
                            // trigger the stack setup again, this time with the upgraded store
                            let _ = CDHelper.shared.localStore
                            dispatch_after(2, dispatch_get_main_queue(), {
                                migrationVC.dismissViewControllerAnimated(false, completion: nil)
                            })
                        })
                    })
                })
            } else {print("FAILED to find a view controller with a story board id of 'migration'")}
        } else {print("FAILED to find the root view controller, which is supposed to be a navigation controller")}
    }

    func migrateStoreIfNecessary (storeURL:NSURL, destinationModel:NSManagedObjectModel) {
        if storeExistsAtPath(storeURL: storeURL) == false {
            return
        }
            
        if store(storeURL: storeURL, isCompatibleWithModel: destinationModel) {
            return
        }
        
        do {
            var _metadata:[String : AnyObject]?
            _metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL as URL, options: nil) as [String : AnyObject]
            if let metadata = _metadata, let sourceModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: metadata) {
                self.migrateStoreWithProgressUI(store: storeURL, sourceModel: sourceModel, destinationModel: destinationModel)
            }
        } catch {
            print("\(#function) FAILED to get metadata \(error)")
        }
    }
}   
