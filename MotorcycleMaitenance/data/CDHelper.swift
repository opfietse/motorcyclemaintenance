//
//  CDHelper.swift
//  Groceries
//
//  Created by Tim Roadley on 29/09/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import UIKit
import CoreData

private let _sharedCDHelper = CDHelper()

class CDHelper : NSObject  {
    
    // MARK: - SHARED INSTANCE
    class var shared : CDHelper {
        return _sharedCDHelper
    }
    
    // MARK: - PATHS
    lazy var storesDirectory: URL? = {
        let fm = FileManager.default
        let urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()

    lazy var localStoreURL: URL? = {
        if let url = self.storesDirectory?.appendingPathComponent("LocalStore.sqlite") {
            print("localStoreURL = \(url)")
            return url
        }
        return nil
    }()

    lazy var iCloudStoreURL: URL? = {
        if let url = self.storesDirectory?.appendingPathComponent("iCloud.sqlite") {
            print("iCloudStoreURL = \(url)")
            return url
        }
        return nil
    }()

    lazy var sourceStoreURL: URL? = {
        if let url = Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite") {
            print("sourceStoreURL = \(url)")
            return url
        }
        return nil
    }()

    lazy var seedStoreURL: URL? = {
        if let url = self.storesDirectory?.appendingPathComponent("LocalStore.sqlite") {
            print("seedStoreURL = \(url)")
            return url
        }
        return nil
    }()

    lazy var modelURL: URL = {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: "Model", withExtension: "momd") {
            return url
        }
        print("CRITICAL - Managed Object Model file not found")
        abort()
    }()
    
    // MARK: - CONTEXT
    lazy var parentContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.coordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var context: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.mainQueueConcurrencyType)
        // moc.persistentStoreCoordinator = self.coordinator
        moc.parent = self.parentContext
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var importContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        //moc.persistentStoreCoordinator = self.coordinator
        moc.parent = self.context
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var sourceContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        //moc.persistentStoreCoordinator = self.coordinator
        moc.parent = self.context
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var seedContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.seedCoordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    
    // MARK: - MODEL
    lazy var model: NSManagedObjectModel = {
        return NSManagedObjectModel(contentsOf:self.modelURL as URL)!
    }()
        
    // MARK: - COORDINATOR
    lazy var coordinator: NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    
    lazy var sourceCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    
    lazy var seedCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
        
    // MARK: - STORE
    lazy var localStore: NSPersistentStore? = {
        let useMigrationManager = false

        if let _localStoreURL = self.localStoreURL {
            if useMigrationManager == true &&
                CDMigration.shared.storeExistsAtPath(storeURL: _localStoreURL) &&
                CDMigration.shared.store(storeURL: _localStoreURL, isCompatibleWithModel: self.model) == false {
                return nil // Don't return a store if it's not compatible with the model
            }
        }
        
        let options:[NSObject:AnyObject] = [//NSSQLitePragmasOption:["journal_mode":"DELETE"],
            NSMigratePersistentStoresAutomaticallyOption as NSObject as NSObject:1 as AnyObject,
            NSInferMappingModelAutomaticallyOption as NSObject:1 as AnyObject]
        var _localStore:NSPersistentStore?
        do {
            _localStore = try self.coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.localStoreURL, options: options)
            return _localStore
        } catch {
            return nil
        }
    }()
    
//    lazy var iCloudStore: NSPersistentStore? = {
//
//       // Change contentNameKey for your own applications
//        let contentNameKey = "opfietse.MotorcycleMaintenance"
//
//        print("Using '\(contentNameKey)' as the iCloud Ubiquitous Content Name Key")
//        let options:[NSObject:AnyObject] =
//            [NSMigratePersistentStoresAutomaticallyOption as NSObject:1 as AnyObject,
//             NSInferMappingModelAutomaticallyOption as NSObject:1 as AnyObject,
//             NSPersistentStoreUbiquitousContentNameKey as NSObject:contentNameKey as AnyObject
//                  //,NSPersistentStoreUbiquitousContentURLKey:"ChangeLogs" // Optional since iOS7
//                    ]
//        var _iCloudStore: NSPersistentStore?
//
//        do {
//            _iCloudStore = try self.coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.iCloudStoreURL, options: options)
//            return _iCloudStore
//        } catch {
//            print("\(#function) ERROR adding iCloud store : \(error)")
//            return nil
//        }
//    }()
    
    lazy var sourceStore: NSPersistentStore? = {
            
        let options:[NSObject:AnyObject] = [NSReadOnlyPersistentStoreOption as NSObject:1 as AnyObject]
            
        var _sourceStore:NSPersistentStore?
        do {
           // self.sourceCoordinator.addP
            _sourceStore = try self.sourceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.sourceStoreURL, options: options)
            return _sourceStore
        } catch {
            return nil
        }
    }()
    
    lazy var seedStore: NSPersistentStore? = {
            
        let options:[NSObject:AnyObject] = [NSReadOnlyPersistentStoreOption as NSObject:1 as AnyObject]
            
        var _seedStore:NSPersistentStore?
        do {
            _seedStore = try self.seedCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.seedStoreURL, options: options)
            return _seedStore
        } catch {
            return nil
        }
    }()

    func unloadStore (ps:NSPersistentStore) -> Bool {
            
        if let psc = ps.persistentStoreCoordinator {
            
            do {
                try psc.remove(ps)
                return true // Unload complete
            } catch {print("\(#function) ERROR removing persistent store : \(error)")}
        } else {print("\(#function) ERROR removing persistent store : store \(ps.description) has no coordinator")}
        return false // Fail
    }
    
    func removeFileAtURL (url:NSURL) {
        do {
            try FileManager.default.removeItem(at: url as URL)
            print("Deleted \(url)")
        } catch { 
            print("\(#function) ERROR deleting item at url '\(url)' : \(error)")
        }
    }
    
    
    // MARK: - SETUP
    required override init() {
        super.init()
        self.setupCoreData()
        self.listenForStoreChanges()
    }
    
    func setupCoreData() {
            
        /*// Model Migration
        if let _localStoreURL = self.localStoreURL {
            CDMigration.shared.migrateStoreIfNecessary(_localStoreURL, destinationModel: self.model)
        } */

        // Load Local Store
     //    self.setDefaultDataStoreAsInitialStore()
     //   _ = self.sourceStore
        _ = self.localStore
            
        /*// Load iCloud Store
        if let _ = self.iCloudStore {
            
            // self.destroyAlliCloudDataForThisApplication()
            
            if let path = self.seedStoreURL?.path {
                // Merge existing data with iCloud
                if NSFileManager.defaultManager().fileExistsAtPath(path) {
                    if let _ = self.seedStore {
                        self.confirmMergeWithiCloud()
                    } else {print("Failed to instantiate seed store")}
                } else {print("Failed to find seed store at '\(path)'")}
            } else {print("Failed to prepare seed store path")}
        } else {print("Failed to load iCloud store")} */
        
        // Import Default Data
        /* if let _localStoreURL = self.localStoreURL {
            CDImporter.shared.checkIfDefaultDataNeedsImporting(_localStoreURL, type: NSSQLiteStoreType)
        } else {print("ERROR getting localStoreURL in \(__FUNCTION__)")}*/
    }
        
    // MARK: - SAVING
    class func save(moc:NSManagedObjectContext) {
        
        moc.performAndWait {
         
            if moc.hasChanges {
            
                do {
                    try moc.save()
                    //print("SAVED context \(moc.description)")
                } catch {
                    print("ERROR saving context \(moc.description) - \(error)")
                }
            } else {
                //print("SKIPPED saving context \(moc.description) because there are no changes")
            }
            if let parentContext = moc.parent {
                save(moc: parentContext)
            }
        }
    }
    class func saveSharedContext() {
        save(moc: shared.context)
    }
    
    // MARK: - DEFAULT STORE
    func setDefaultDataStoreAsInitialStore () {
         let url = self.localStoreURL
         let path = url!.path
            if FileManager.default.fileExists(atPath: path) == false {
                if let defaultDataURL = Bundle.main.url(forResource: "DefaultData", withExtension: "sqlite") {
                    do {
                        try FileManager.default.copyItem(at: defaultDataURL, to: url!)
                        print("A copy of DefaultData.sqlite was set as the initial store for \(String(describing: url))")
                    } catch {
                        print("\(#function) ERROR setting DefaultData.sqlite as the initial store: : \(error)")
                    }
                } else {print("\(#function) ERROR: Could not find DefaultData.sqlite in the application bundle.")}
            } 
        
        print("\(#function) ERROR: Failed to prepare URL in \(#function)")
    } 
    
    // MARK: - ICLOUD
    func iCloudAccountIsSignedIn() -> Bool {

        if let token = FileManager.default.ubiquityIdentityToken {
            print("** This device is SIGNED IN to iCloud with token \(token) **")
            return true
        }

        print("\rThis application cannot use iCloud because it is either signed out or is disabled for this App.")
        print("If the device is signed in and you still get this error, verify the following:")
        print("1) iCloud Documents is ticked in Xcode (Application Target > Capabilities > iCloud.)")
        print("2) The App ID is enabled for iCloud in the Member Center (https://developer.apple.com/)")
        print("3) The App is enabled for iCloud on the Device (Settings > iCloud > iCloud Drive)")
        return false
    }
    
    func listenForStoreChanges () {
        let dc = NotificationCenter.default
        dc.addObserver(self, selector: Selector(("storesWillChange:")), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: self.coordinator)
        dc.addObserver(self, selector: Selector(("storesDidChange:")), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: self.coordinator)
        dc.addObserver(self, selector: Selector(("iCloudDataChanged:")), name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object:self.coordinator)
    }
    
    func storesWillChange (note:NSNotification) {
        self.sourceContext.performAndWait {
            do {
                try self.sourceContext.save()
                self.sourceContext.reset()
            } catch {print("ERROR saving sourceContext \(self.sourceContext.description) - \(error)")}
        }
        self.importContext.performAndWait {
            do {
                try self.importContext.save()
                self.importContext.reset()
            } catch {print("ERROR saving importContext \(self.importContext.description) - \(error)")}
        }
        self.context.performAndWait {
            do {
                try self.context.save()
                self.context.reset()
            } catch {print("ERROR saving context \(self.context.description) - \(error)")}
        }
        self.parentContext.performAndWait {
            do {
                try self.parentContext.save()
                self.parentContext.reset()
            } catch {print("ERROR saving parentContext \(self.parentContext.description) - \(error)")}
        }
    }

    func storesDidChange (note:NSNotification) {
        // Refresh UI
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
    }

    func iCloudDataChanged (note:NSNotification) {
        // Refresh UI Context
        self.context.mergeChanges(fromContextDidSave: note as Notification)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
    }

    func seedDataToiCloud () {
        self.seedContext.perform {
//
//            print("*** STARTED DEEP COPY FROM SEED STORE TO ICLOUD STORE ***")
//            _ = self.seedStore
//            let entities = ["LocationAtHome","LocationAtShop","Unit","Item"]
//            CDImporter.deepCopyEntities(entities, from: self.seedContext, to: self.importContext)
//
//            self.context.perform {
//
//                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
//                print("*** FINISHED DEEP COPY FROM SEED STORE TO ICLOUD STORE ***")
//
//                // Remove seed store
//                if let _seedStoreURL = self.seedStoreURL {
//
//                    if let wal = _seedStoreURL.path?.stringByAppendingString("-wal") {
//                        self.removeFileAtURL(NSURL(fileURLWithPath: wal))
//                    }
//
//                    if let shm = _seedStoreURL.path?.stringByAppendingString("-shm") {
//                        self.removeFileAtURL(NSURL(fileURLWithPath: shm))
//                    }
//                    self.removeFileAtURL(url: _seedStoreURL)
//                }
//            }
        }
    }

    func confirmMergeWithiCloud () {

        if let path = self.seedStoreURL?.path {

            if FileManager.default.fileExists(atPath: path) {

                let alert = UIAlertController(title: "Merge with iCloud?", message: "This will move your existing data into iCloud.", preferredStyle: .alert)
                let mergeButton = UIAlertAction(title: "Merge", style: .default, handler: { (action) -> Void in

                    self.seedDataToiCloud()
                })
                let dontMergeButton = UIAlertAction(title: "Don't Merge", style: .default, handler: { (action) -> Void in

                    // Don't do anything. In your own applications, store this decision.
                })
                alert.addAction(mergeButton)
                alert.addAction(dontMergeButton)

                // PRESENT
                DispatchQueue.main.async(execute: { () -> Void in
                    if let initialVC = UIApplication.shared.keyWindow?.rootViewController {
                        initialVC.present(alert, animated: true, completion: nil)
                    } else {print("%@ FAILED to prepare the initial view controller",#function)}
                })

            } else {
                print("Skipped unnecessary migration of seed store to iCloud (there's no store file).")
            }
        }
    }
    
    // MARK: - ICLOUD RESET (only for use during testing, not production)
//    func destroyAlliCloudDataForThisApplication () {
//        print("Attempting to destroy all iCloud content for this application, which could take a while...")
//
//        let persistentStoreCoordinators = [self.coordinator,self.seedCoordinator,self.sourceCoordinator]
//        for persistentStoreCoordinator in persistentStoreCoordinators {
//            for persistentStore in persistentStoreCoordinator.persistentStores {
//               _ = self.unloadStore(ps: persistentStore)
//            }
//        }
//
//        if let _iCloudStoreURL = self.iCloudStoreURL {
//            do {
//
//                let options = [NSPersistentStoreUbiquitousContentNameKey:"opfietse.MotorcycleMaintenance"]
//                try NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStore(at: _iCloudStoreURL as URL, options: options)
//                print("\n\n\n")
//                print("*          This application's iCloud content has been destroyed.          *")
//                print("*   On ALL devices, please delete any reference to this application from  *")
//                print("*                      Settings > iCloud > Storage                        *")
//                print("*                                                                         *")
//                print("* The application is force closed to ensure iCloud data is wiped cleanly. *")
//                print("\n\n\n")
//                abort()
//
//            } catch {print("\n\n FAILED to destroy iCloud content - \(error)")}
//        } else {print("\n\n FAILED to destroy iCloud content because _iCloudStoreURL is nil.")}
//    }
    
}
