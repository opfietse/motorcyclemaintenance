//
//  CDImporter.swift
//  Groceries
//
//  Created by Tim Roadley on 5/10/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import Foundation
import CoreData
import UIKit

struct JsonTask : Codable {
    let id: String
    let taskDescription: String
    //
    //    enum CodingKeys : String, CodingKey {
    //        case id
    //        case tdesc = "taskDescription"
    //    }
}

struct JsonMotorcycleType : Codable {
    let make: String
    let model: String
    let year: Int16
}

struct JsonMotorcycle : Codable {
    let registration: String
    let motorcycleTypeMake: String
    let motorcycleTypeModel: String
    let motorcycleTypeYear: Int16
}

struct JsonMotorcycleMaintenance : Codable {
    let motorcycleRegistration: String
    let creationDate: Date
    let startDate: Date?
    let endDate: Date?
    let remarks: String?
}

struct JsonMotorcycleTypeTask : Codable {
    let mileageInterval: Int16
    let timeInterval: Int16
    let taskId: String
}

struct JsonMotorcycleTypeMaintenanceTask : Codable {
    let motorcycleType: JsonMotorcycleType
    let tasks: [JsonMotorcycleTypeTask]
}

struct JsonMotorcycleMaintenanceWithTasks : Codable {
    struct JsonMotorcycleMaintenanceTask : Codable {
        let taskId: String
        let completionDate: Date
        let mileage: Int16
        let remarks: String
    }
    
    struct JsonMotorcycleMaintenanceForTask : Codable {
        let motorcycleRegistration: String
        let creationDate: Date
    }
    
    let motorcycleMaintenance: JsonMotorcycleMaintenanceForTask
    let tasks: [JsonMotorcycleMaintenanceTask]
}

private let _sharedCDImporter = CDImporter()

class CDImporter : NSObject, XMLParserDelegate {
    
    // MARK: - SHARED INSTANCE
    class var shared : CDImporter {
        return _sharedCDImporter
    }
    
    // MARK: - DATA IMPORT
    class func isDefaultDataAlreadyImportedForStoreWithURL (url:URL, type:String) -> Bool {
        do {
            var metadata:[String : AnyObject]?
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url, options: nil) as [String : AnyObject]
            
            if let dictionary = metadata {
                if let defaultDataAlreadyImported = dictionary["DefaultDataImported"] as? NSNumber {
                    if defaultDataAlreadyImported.boolValue == false {
                        print("Default Data has not been imported yet")
                        return false
                    } else {
                        print("Default Data import is not required")
                        return true
                    }
                } else {
                    print("Default Data has not been imported yet")
                    return false
                }
            } else {print("\(#function) FAILED to get metadata")}
        } catch {
            print("ERROR getting metadata from \(url) \(error)")
        }
        
        return true // default to true to prevent a default data import when an error occurs
    }
    
    func checkIfDefaultDataNeedsImporting (url:URL, type:String) {
        if CDImporter.isDefaultDataAlreadyImportedForStoreWithURL(url: url, type: type) == false {
            
            let alert = UIAlertController(title: "Import Default Data?", message: "If you've never used this application before then some default data might help you understand how to use it. Tap 'Import' to import default data. Tap 'Cancel' to skip the import, especially if you've done this before on your other devices.", preferredStyle: .alert)
            
            let importButton = UIAlertAction(title: "Import", style: .destructive, handler: { (action) -> Void in
                self.importJsonTasks()
                self.importMotorcycleTypes()
                self.importMotorcycleTypeMaintenanceTasks()
                self.importMotorcycles()
                self.importMotorcycleMaintenances()
                self.importMotorcycleMaintenanceTasks()
                
                //                // Import data
                //                if let url = Bundle.main.url(forResource: "DefaultData", withExtension: "xml") {
                //                    CDHelper.shared.importContext.perform {
                //                        print("Attempting DefaultData.xml Import...")
                //                        self.importFromXML(url: url)
                //                        //print("Attempting DefaultData.sqlite Import...")
                //                        //CDImporter.triggerDeepCopy(CDHelper.shared.sourceContext, targetContext: CDHelper.shared.importContext, mainContext: CDHelper.shared.context)
                //                    }
                //                } else {
                //                    print("DefaultData.xml not found")
                //                }
                
                // Set the data as imported
                if let store = CDHelper.shared.localStore {
                    self.setDefaultDataAsImportedForStore(store: store)
                }
            })
            
            let skipButton = UIAlertAction(title: "Skip", style: .default, handler: { (action) -> Void in
                // Set the data as imported
                if let store = CDHelper.shared.localStore {
                    self.setDefaultDataAsImportedForStore(store: store)
                }
            })
            alert.addAction(importButton)
            alert.addAction(skipButton)
            
            // PRESENT
            //            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //                if let initialVC = UIApplication.shared.keyWindow?.rootViewController {
            //                    initialVC.present(alert, animated: true, completion: nil)
            //                } else {NSLog("ERROR getting the initial view controller in %@",#function)}
            //            })
            DispatchQueue.main.async(execute: { () -> Void in
                if let initialVC = UIApplication.shared.keyWindow?.rootViewController {
                    initialVC.present(alert, animated: true, completion: nil)
                } else {
                    NSLog("ERROR getting the initial view controller in %@",#function)
                }
            })
        }
    }
    
    func setDefaultDataAsImportedForStore (store:NSPersistentStore) {
        if let coordinator = store.persistentStoreCoordinator {
            var metadata = store.metadata
            metadata!["DefaultDataImported"] = NSNumber(value: true)
            coordinator.setMetadata(metadata, for: store)
            print("Store metadata after setDefaultDataAsImportedForStore \(store.metadata)")
        }
    }
    
    // MARK: - JSON files
    func importJsonTasks() {
        if let storesDirectory = CDHelper.shared.storesDirectory {
            //            let tasksUrl = storesDirectory.appendingPathComponent("tasks.json")
            let url = storesDirectory.appendingPathComponent("tasks.json")
            print("URL path: \(url.path)")
            print("URL absolute path: \(url.absoluteString)")
            if FileManager.default.fileExists(atPath: url.path) {//Bundle.main.url(forResource: "tasks", withExtension: "json") {
                print("File tasks.json found: \(url)")
                
                do {
                    let tasksAsString = try String(contentsOf: url, encoding: .utf8)
                    let tasksJsonData = tasksAsString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let tasks: [JsonTask] = try! decoder.decode([JsonTask].self, from: tasksJsonData)
                    
                    let importContext = CDHelper.shared.importContext
                    
                    for task in tasks {
                        print("Task id \(task.id)")
                        
                        let task1: Task = (NSEntityDescription.insertNewObject(forEntityName: "Task", into: importContext) as? Task)!
                        task1.id = task.id
                        task1.taskDescription = task.taskDescription
                    }
                    
                    CDHelper.save(moc: importContext)
                } catch let e as NSError {
                    print("File read \(url) failed \(e)")
                }
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            } else {
                print("File tasks.json not found: \(url)")
            }
        }
    }
    
    func importMotorcycleTypes() {
        if let storesDirectory = CDHelper.shared.storesDirectory {
            let url = storesDirectory.appendingPathComponent("motorcycleTypes.json")
            if FileManager.default.fileExists(atPath: url.path) {//Bundle.main.url(forResource: "motorcycleTypes", withExtension: "json") {
                print("File motorcycleTypes.json found: \(url)")
                
                do {
                    let motorcycleTypesAsString = try String(contentsOf: url, encoding: .utf8)
                    let motorcycleTypesJsonData = motorcycleTypesAsString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let motorcycleTypes: [JsonMotorcycleType] = try! decoder.decode([JsonMotorcycleType].self, from: motorcycleTypesJsonData)
                    
                    let importContext = CDHelper.shared.importContext
                    
                    for motorcycleType in motorcycleTypes {
                        print("Mc make \(motorcycleType.make)")
                        
                        let motorcycleType1: MotorcycleType = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleType", into: importContext) as? MotorcycleType)!
                        motorcycleType1.make = motorcycleType.make
                        motorcycleType1.model = motorcycleType.model
                        motorcycleType1.year = motorcycleType.year
                    }
                    
                    CDHelper.save(moc: importContext)
                } catch let e as NSError {
                    print("File read \(url) failed \(e)")
                }
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func importMotorcycleTypeMaintenanceTasks() {
        if let storesDirectory = CDHelper.shared.storesDirectory {
            let url = storesDirectory.appendingPathComponent("motorcycleTypeMaintenanceTasks.json")
            if FileManager.default.fileExists(atPath: url.path) {//Bundle.main.url(forResource: "motorcycleTypeMaintenanceTasks", withExtension: "json") {
                print("File motorcycleTypeMaintenanceTasks found: \(url)")
                
                do {
                    let motorcycleTypeMaintenanceTasksAsString = try String(contentsOf: url, encoding: .utf8)
                    let motorcycleTypeMaintenanceTasksJsonData = motorcycleTypeMaintenanceTasksAsString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let motorcycleTypeMaintenanceTasks: [JsonMotorcycleTypeMaintenanceTask] = try! decoder.decode([JsonMotorcycleTypeMaintenanceTask].self, from: motorcycleTypeMaintenanceTasksJsonData)
                    
                    let importContext = CDHelper.shared.importContext
                    
                    for motorcycleTypeMaintenanceTask in motorcycleTypeMaintenanceTasks {
                        print("Mc \(motorcycleTypeMaintenanceTask.motorcycleType.make)")
                        
                        if let mcType = self.fetchMotorcycleType(make: motorcycleTypeMaintenanceTask.motorcycleType.make, model: motorcycleTypeMaintenanceTask.motorcycleType.model, year: motorcycleTypeMaintenanceTask.motorcycleType.year) {
                            
                            for mctTask in motorcycleTypeMaintenanceTask.tasks {
                                if let task = self.fetchTask(taskId: mctTask.taskId) {
                                    
                                    let motorcycleTypeMaintenanceTask1: MotorcycleTypeMaintenanceTask = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleTypeMaintenanceTask", into: importContext) as? MotorcycleTypeMaintenanceTask)!
                                    motorcycleTypeMaintenanceTask1.motorcycleType = mcType
                                    motorcycleTypeMaintenanceTask1.task = task
                                    motorcycleTypeMaintenanceTask1.mileageInterval = mctTask.mileageInterval
                                    motorcycleTypeMaintenanceTask1.timeInterval = mctTask.timeInterval
                                }
                            }
                        }
                    }
                    
                    CDHelper.save(moc: importContext)
                } catch let e as NSError {
                    print("File read \(url) failed \(e)")
                }
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func importMotorcycleMaintenanceTasks() {
        if let storesDirectory = CDHelper.shared.storesDirectory {
            let url = storesDirectory.appendingPathComponent("motorcycleMaintenanceTasks.json")
            if FileManager.default.fileExists(atPath: url.path) {//Bundle.main.url(forResource: "motorcycleMaintenanceTasks", withExtension: "json") {
                print("File motorcycleMaintenanceTasks found: \(url)")
                
                do {
                    let motorcycleMaintenanceTasksAsString = try String(contentsOf: url, encoding: .utf8)
                    let motorcycleMaintenanceTasksJsonData = motorcycleMaintenanceTasksAsString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let motorcycleMaintenancesWithTasks: [JsonMotorcycleMaintenanceWithTasks] = try! decoder.decode([JsonMotorcycleMaintenanceWithTasks].self, from: motorcycleMaintenanceTasksJsonData)
                    
                    let importContext = CDHelper.shared.importContext
                    
                    for motorcycleMaintenanceWithTasks in motorcycleMaintenancesWithTasks {
                        print("McM \(motorcycleMaintenanceWithTasks.motorcycleMaintenance.motorcycleRegistration)")
                        
                        if let mcm = self.fetchMotorcycleMaintenance(registration: motorcycleMaintenanceWithTasks.motorcycleMaintenance.motorcycleRegistration, creationDate: motorcycleMaintenanceWithTasks.motorcycleMaintenance.creationDate) {
                            
                            for mcTask in motorcycleMaintenanceWithTasks.tasks {
                                if let mcTypeMaintenanceTask = self.fetchMotorcycleTypeMaintenanceTask(motorcycleType: (mcm.motorcycle?.motorcycleType)!, taskId: mcTask.taskId) {
                                    
                                    print("McTMT \(mcTypeMaintenanceTask.motorcycleType?.model ?? "Defval")")
                                    print("Task \(mcTypeMaintenanceTask.task?.id ?? "DefvalTask")")
                                    
                                    let motorcycleMaintenanceTask1: MotorcycleMaintenanceTask = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleMaintenanceTask", into: importContext) as? MotorcycleMaintenanceTask)!
                                    
                                    motorcycleMaintenanceTask1.motorcycleMaintenance = mcm
                                    motorcycleMaintenanceTask1.motorcycleTypeMaintenanceTask = mcTypeMaintenanceTask
                                    motorcycleMaintenanceTask1.completionDate = mcTask.completionDate
                                    motorcycleMaintenanceTask1.mileage = mcTask.mileage
                                    motorcycleMaintenanceTask1.remarks = mcTask.remarks
                                } else {
                                    print("mcTask with \(mcTask.taskId) not found")
                                }
                            }
                        }
                    }
                    
                    CDHelper.save(moc: importContext)
                } catch let e as NSError {
                    print("File read \(url) failed \(e)")
                }
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func fetchMotorcycle(registration: String) -> Motorcycle? {
        let motorcyclesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Motorcycle")
        
        let registrationPredicate = NSPredicate(format: "registration == %@", registration)
        
        motorcyclesFetch.predicate = registrationPredicate
        
        do {
            let fetchedMotorcycles = try CDHelper.shared.importContext.fetch(motorcyclesFetch) as! [Motorcycle]

            if fetchedMotorcycles.count > 1 {
                print("More than one motorcycle found for registration \(registration)")
                return nil
            }
            
            if let mc = fetchedMotorcycles.first {
                return mc
            }
        } catch {
            fatalError("Failed to fetch Motorcycles: \(error)")
        }
        
        return nil
    }
    
    func fetchMotorcycleMaintenance(registration: String, creationDate: Date) -> MotorcycleMaintenance? {
        let motorcycleMaintenancesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MotorcycleMaintenance")
        
        let registrationPredicate = NSPredicate(format: "motorcycle.registration == %@", registration)
        let creationDatePredicate = NSPredicate(format: "creationDate == %@", creationDate as NSDate)
        let motorcycleTMaintenancePredicate = NSCompoundPredicate(type: .and, subpredicates: [registrationPredicate, creationDatePredicate])
        
        motorcycleMaintenancesFetch.predicate = motorcycleTMaintenancePredicate
        
        do {
            let fetchedMotorcycleMaintenances = try CDHelper.shared.importContext.fetch(motorcycleMaintenancesFetch) as! [MotorcycleMaintenance]

            if fetchedMotorcycleMaintenances.count > 1 {
                print("More than one motorcycle maintenance found for registration \(registration) and date \(creationDate)")
                return nil
            }

            if let mcm = fetchedMotorcycleMaintenances.first {
                return mcm
            }
        } catch {
            fatalError("Failed to fetch Motorcycle maintenances: \(error)")
        }
        
        return nil
    }
    
    func fetchTask(taskId: String) -> Task? {
        let tasksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        
        let taskIdPredicate = NSPredicate(format: "id == %@", taskId)
        
        tasksFetch.predicate = taskIdPredicate
        
        do {
            let fetchedTasks = try CDHelper.shared.importContext.fetch(tasksFetch) as! [Task]

            if fetchedTasks.count > 1 {
                print("More than one task found for id \(taskId)")
                return nil
            }

            if let task = fetchedTasks.first {
                return task
            }
        } catch {
            fatalError("Failed to fetch Tasks: \(error)")
        }
        
        return nil
    }
    
    func fetchMotorcycleTypeMaintenanceTask(motorcycleType: MotorcycleType , taskId: String) -> MotorcycleTypeMaintenanceTask? {
        let motorcycleTypeMaintenanceTasksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MotorcycleTypeMaintenanceTask")
        
        let mcTypePredicate = NSPredicate(format: "motorcycleType == %@", motorcycleType)
        let taskIdPredicate = NSPredicate(format: "task.id == %@", taskId)
        let motorcycleTypeMaintenanceTaskPredicate = NSCompoundPredicate(type: .and, subpredicates: [mcTypePredicate, taskIdPredicate])
        
        motorcycleTypeMaintenanceTasksFetch.predicate = motorcycleTypeMaintenanceTaskPredicate
        
        do {
            let fetchedMotorcycleTypeMaintenanceTask = try CDHelper.shared.importContext.fetch(motorcycleTypeMaintenanceTasksFetch) as! [MotorcycleTypeMaintenanceTask]

            if fetchedMotorcycleTypeMaintenanceTask.count > 1 {
                print("More than one motorcycle type maintenance task found for motorcycle type \(motorcycleType.model ?? "No mctype model!") id \(taskId)")
                return nil
            }
            
            if let task = fetchedMotorcycleTypeMaintenanceTask.first {
                return task
            }
        } catch {
            fatalError("Failed to fetch MotorcycleTypeMaintenanceTask: \(error)")
        }
        
        return nil
    }
    
    func fetchMotorcycleType(make: String, model: String, year: Int16) -> MotorcycleType? {
        let motorcycleTypesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MotorcycleType")
        
        let modelPredicate = NSPredicate(format: "make == %@", make)
        let makePredicate = NSPredicate(format: "model == %@", model)
        let yearPredicate = NSPredicate(format: "year == %d", year)
        let motorcycleTypePredicate = NSCompoundPredicate(type: .and, subpredicates: [makePredicate, modelPredicate, yearPredicate])
        
        motorcycleTypesFetch.predicate = motorcycleTypePredicate
        
        do {
            let fetchedMotorcycleTypes = try CDHelper.shared.importContext.fetch(motorcycleTypesFetch) as! [MotorcycleType]

            if fetchedMotorcycleTypes.count > 1 {
                print("More than one motorcycle type found for make \(make), model \(model) and year \(year)")
                return nil
            }
            
            if let mcType = fetchedMotorcycleTypes.first {
                return mcType
            }
        } catch {
            fatalError("Failed to fetch MotorcycleTypes: \(error)")
        }
        
        return nil
    }
    
    func importMotorcycles() {
        if let storesDirectory = CDHelper.shared.storesDirectory {
            let url = storesDirectory.appendingPathComponent("motorcycles.json")
            if FileManager.default.fileExists(atPath: url.path) {//Bundle.main.url(forResource: "motorcycles", withExtension: "json") {
                print("File motorcycles.json found: \(url)")
                
                do {
                    let motorcyclesAsString = try String(contentsOf: url, encoding: .utf8)
                    let motorcyclesJsonData = motorcyclesAsString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let motorcycles: [JsonMotorcycle] = try! decoder.decode([JsonMotorcycle].self, from: motorcyclesJsonData)
                    
                    let importContext = CDHelper.shared.importContext
                    
                    for motorcycle in motorcycles {
                        print("Mc reg. \(motorcycle.registration)")
                        
                        if self.fetchMotorcycle(registration: motorcycle.registration) != nil {
                            print("\(motorcycle.registration) already exists")
                        } else {
                            if let mcType = self.fetchMotorcycleType(make: motorcycle.motorcycleTypeMake, model: motorcycle.motorcycleTypeModel, year: motorcycle.motorcycleTypeYear) {
                                let motorcycle1: Motorcycle = (NSEntityDescription.insertNewObject(forEntityName: "Motorcycle", into: importContext) as? Motorcycle)!
                                motorcycle1.registration = motorcycle.registration
                                motorcycle1.motorcycleType = mcType
                            } else {
                                print("Motorcycle type \(motorcycle.motorcycleTypeMake) \(motorcycle.motorcycleTypeModel) \(motorcycle.motorcycleTypeYear) not found!")
                            }
                        }
                    }
                    
                    CDHelper.save(moc: importContext)
                } catch let e as NSError {
                    print("File read \(url) failed \(e)")
                }
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func importMotorcycleMaintenances() {
        if let storesDirectory = CDHelper.shared.storesDirectory {
            let url = storesDirectory.appendingPathComponent("motorcycleMaintenances.json")
            if FileManager.default.fileExists(atPath: url.path) {//Bundle.main.url(forResource: "motorcycleMaintenances", withExtension: "json") {
                print("File motorcycleMaintenances found: \(url)")
                
                do {
                    let motorcycleMaintenancesAsString = try String(contentsOf: url, encoding: .utf8)
                    let motorcycleMaintenancesJsonData = motorcycleMaintenancesAsString.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let motorcycleMaintenances: [JsonMotorcycleMaintenance] = try! decoder.decode([JsonMotorcycleMaintenance].self, from: motorcycleMaintenancesJsonData)
                    
                    let importContext = CDHelper.shared.importContext
                    
                    for motorcycleMaintenance in motorcycleMaintenances {
                        print("Mc reg. \(motorcycleMaintenance.motorcycleRegistration)")
                        
                        //                    if self.fetchMotorcycle(registration: motorcycle.registration) != nil {
                        //                        print("\(motorcycle.registration) already exists")
                        //                    } else {
                        if let mc = self.fetchMotorcycle(registration: motorcycleMaintenance.motorcycleRegistration) {
                            let motorcycleMaintenance1: MotorcycleMaintenance = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleMaintenance", into: importContext) as? MotorcycleMaintenance)!
                            motorcycleMaintenance1.motorcycle = mc
                            motorcycleMaintenance1.creationDate = motorcycleMaintenance.creationDate
                            motorcycleMaintenance1.startDate = motorcycleMaintenance.startDate
                            motorcycleMaintenance1.endDate = motorcycleMaintenance.endDate
                            motorcycleMaintenance1.remarks = motorcycleMaintenance.remarks
                        } else {
                            print("Motorcycle \(motorcycleMaintenance.motorcycleRegistration) not found!")
                        }
                        //                    }
                    }
                    
                    CDHelper.save(moc: importContext)
                } catch let e as NSError {
                    print("File read \(url) failed \(e)")
                }
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print(error)
                }
            }
        }
    }
}
