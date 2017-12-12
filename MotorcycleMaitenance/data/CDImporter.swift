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

/*
 [
 {
 "motorcycleMaintenance": {
 "motorcycleRegistration": "15-MG-SK",
 "creationDate": "2017-11-20T23:00:00Z"
 },
 "tasks": [
 {
 "taskId": "MOV",
 "completionDate": "2017-11-20T23:00:00Z",
 "milage": 9023,
 "remarks": "Opmerking Duc MOV 9023"
 },
 {
 "taskId": "OFV",
 "completionDate": "2017-11-20T23:00:00Z",
 "milage": 9023,
 "remarks": "Opmerking Duc OFV 9023"
 }
 ]
 }
 ]
 
 
 
 
 
 
 
 
 
 [
 {
 "motorcycleMaintenance": {
 "motorcycleRegistration": "15-MG-SK",
 "creationDate": "2017-11-20T23:00:00Z"
 },
 "tasks": [
 {
 "taskId": "MOV",
 "completionDate": "2017-11-20T23:00:00Z",
 "milage": 9023,
 "remarks": "Opmerking Duc MOV 9023"
 },
 {
 "taskId": "OFV",
 "completionDate": "2017-11-20T23:00:00Z",
 "milage": 9023,
 "remarks": "Opmerking Duc OFV 9023"
 }
 ]
 }
 ]

 */

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
                
                // Import data
                if let url = Bundle.main.url(forResource: "DefaultData", withExtension: "xml") {
                    CDHelper.shared.importContext.perform {
                        print("Attempting DefaultData.xml Import...")
                        self.importFromXML(url: url)
                        //print("Attempting DefaultData.sqlite Import...")
                        //CDImporter.triggerDeepCopy(CDHelper.shared.sourceContext, targetContext: CDHelper.shared.importContext, mainContext: CDHelper.shared.context)
                    }
                } else {
                    print("DefaultData.xml not found")
                }
                
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
        if let url = Bundle.main.url(forResource: "tasks", withExtension: "json") {
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
        }
    }
    
    func importMotorcycleTypes() {
        if let url = Bundle.main.url(forResource: "motorcycleTypes", withExtension: "json") {
            print("File motorcycleTypes.json found: \(url)")
            
            do {
                let motorcycleTypesAsString = try String(contentsOf: url, encoding: .utf8)
                let motorcycleTypesJsonData = motorcycleTypesAsString.data(using: .utf8)!
                let decoder = JSONDecoder()
                let motorcycleTypes: [JsonMotorcycleType] = try! decoder.decode([JsonMotorcycleType].self, from: motorcycleTypesJsonData)
                
                let importContext = CDHelper.shared.importContext
                
                for motorcycleType in motorcycleTypes {
                    print("Task id \(motorcycleType.make)")
                    
                    let motorcycleType1: MotorcycleType = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleType", into: importContext) as? MotorcycleType)!
                    motorcycleType1.make = motorcycleType.make
                    motorcycleType1.model = motorcycleType.model
                    motorcycleType1.year = motorcycleType.year
                }
                
                CDHelper.save(moc: importContext)
            } catch let e as NSError {
                print("File read \(url) failed \(e)")
            }
        }
    }
    
    func importMotorcycleTypeMaintenanceTasks() {
        if let url = Bundle.main.url(forResource: "motorcycleTypeMaintenanceTasks", withExtension: "json") {
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
        }
    }
    
    func importMotorcycleMaintenanceTasks() {
        if let url = Bundle.main.url(forResource: "motorcycleMaintenanceTasks", withExtension: "json") {
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
        }
    }

    func fetchMotorcycle(registration: String) -> Motorcycle? {
        let motorcyclesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Motorcycle")
        
        let registrationPredicate = NSPredicate(format: "registration == %@", registration)
        
        motorcyclesFetch.predicate = registrationPredicate
        
        do {
            let fetchedMotorcycles = try CDHelper.shared.importContext.fetch(motorcyclesFetch) as! [Motorcycle]
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
            if let task = fetchedTasks.first {
                return task
            }
        } catch {
            fatalError("Failed to fetch Tasks: \(error)")
        }
        
        return nil
    }
    
    func fetchMotorcycleTypeMaintenanceTask(motorcycleType: MotorcycleType , taskId: String) -> MotorcycleTypeMaintenanceTask? {
        let tasksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MotorcycleTypeMaintenanceTask")
        
        let mcTypePredicate = NSPredicate(format: "motorcycleType == %@", motorcycleType)
        let taskIdPredicate = NSPredicate(format: "task.id == %@", taskId)
        let motorcycleTypeMaintenanceTaskPredicate = NSCompoundPredicate(type: .and, subpredicates: [mcTypePredicate, taskIdPredicate])

        tasksFetch.predicate = motorcycleTypeMaintenanceTaskPredicate
        
        do {
            let fetchedTasks = try CDHelper.shared.importContext.fetch(tasksFetch) as! [MotorcycleTypeMaintenanceTask]
            if let task = fetchedTasks.first {
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
            if let mcType = fetchedMotorcycleTypes.first {
                return mcType
            }
        } catch {
            fatalError("Failed to fetch MotorcycleTypes: \(error)")
        }
        
        return nil
    }
    
    func importMotorcycles() {
        if let url = Bundle.main.url(forResource: "motorcycles", withExtension: "json") {
            print("File motorcycles.json found: \(url)")
            
            do {
                let motorcyclesAsString = try String(contentsOf: url, encoding: .utf8)
                let motorcyclesJsonData = motorcyclesAsString.data(using: .utf8)!
                let decoder = JSONDecoder()
                let motorcycles: [JsonMotorcycle] = try! decoder.decode([JsonMotorcycle].self, from: motorcyclesJsonData)
                
                let importContext = CDHelper.shared.importContext
                
                for motorcycle in motorcycles {
                    print("Task id \(motorcycle.registration)")
                    
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
        }
    }
    
    func importMotorcycleMaintenances() {
        if let url = Bundle.main.url(forResource: "motorcycleMaintenances", withExtension: "json") {
            print("File motorcycleMaintenances found: \(url)")
            
            do {
                let motorcycleMaintenancesAsString = try String(contentsOf: url, encoding: .utf8)
                let motorcycleMaintenancesJsonData = motorcycleMaintenancesAsString.data(using: .utf8)!
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let motorcycleMaintenances: [JsonMotorcycleMaintenance] = try! decoder.decode([JsonMotorcycleMaintenance].self, from: motorcycleMaintenancesJsonData)
                
                let importContext = CDHelper.shared.importContext
                
                for motorcycleMaintenance in motorcycleMaintenances {
                    print("Task id \(motorcycleMaintenance.motorcycleRegistration)")
                    
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
        }
    }
    
    // MARK: - XML PARSER
    var parser:XMLParser?
    func importFromXML (url:URL) {
        
        self.parser = XMLParser(contentsOf: url)
        if let _parser = self.parser {
            _parser.delegate = self
            
            //  NSLog("START PARSE OF %@",url)
            _parser.parse()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SomethingChanged"), object: nil)
            // NSLog("END PARSE OF %@",url)
        }
    }
    
    // MARK: - DELEGATE: NSXMLParser
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        NSLog("ERROR PARSING: %@",parseError.localizedDescription)
    }
    
    // NOTE: - The code in the didStartElement function is customized for 'Groceries'
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        //        let importContext = CDHelper.shared.importContext
        //        importContext.performAndWait {
        //
        //            // Process only the 'Item' element in the XML file
        //            if elementName == "Item" {
        //
        //                // STEP 1a: Insert a unique 'Item' object
        //                var item:Item?
        //                if let itemName = attributeDict["name"] {
        //                    item = CDOperation.insertUniqueObject("Item", context: importContext, uniqueAttributes: ["name":itemName], additionalAttributes: nil) as? Item
        //                    if let _item = item {_item.name = itemName}
        //                }
        //
        //                // STEP 1b: Insert a unique 'Unit' object
        //                var unit:Unit?
        //                if let unitName = attributeDict["unit"] {
        //                    unit = CDOperation.insertUniqueObject("Unit", context: importContext, uniqueAttributes: ["name":unitName], additionalAttributes: nil) as? Unit
        //                    if let _unit = unit {_unit.name = unitName}
        //                }
        //
        //                // STEP 1c: Insert a unique 'LocationAtHome' object
        //                var locationAtHome:LocationAtHome?
        //                if let storedIn = attributeDict["locationAtHome"] {
        //                    locationAtHome = CDOperation.insertUniqueObject("LocationAtHome", context: importContext, uniqueAttributes: ["storedIn":storedIn], additionalAttributes: nil) as? LocationAtHome
        //                    if let _locationAtHome = locationAtHome {_locationAtHome.storedIn = storedIn}
        //                }
        //
        //                // STEP 1d: Insert a unique 'LocationAtShop' object
        //                var locationAtShop:LocationAtShop?
        //                if let aisle = attributeDict["locationAtShop"] {
        //                    locationAtShop = CDOperation.insertUniqueObject("LocationAtShop", context: importContext, uniqueAttributes: ["aisle":aisle], additionalAttributes: nil) as? LocationAtShop
        //                    if let _locationAtShop = locationAtShop {_locationAtShop.aisle = aisle}
        //                }
        //
        //                // STEP 2: Manually add extra attribute values.
        //                if let _item = item {_item.listed = NSNumber(bool: false)}
        //
        //                // STEP 3: Create relationships
        //                if let _item = item {
        //
        //                    _item.unit = unit
        //                    _item.locationAtHome = locationAtHome
        //                    _item.locationAtShop = locationAtShop
        //                }
        //
        //                // STEP 4: Save new objects to the persistent store.
        //                CDHelper.save(moc: importContext)
        //
        //                // STEP 5: Turn objects into faults to save memory
        //                if let _item = item { CDFaulter.faultObject(_item, moc: importContext)}
        //                if let _unit = unit { CDFaulter.faultObject(_unit, moc: importContext)}
        //                if let _locationAtHome = locationAtHome { CDFaulter.faultObject(_locationAtHome, moc: importContext)}
        //                if let _locationAtShop = locationAtShop { CDFaulter.faultObject(_locationAtShop, moc: importContext)}
        //            }
        //        }
    }
    
    // MARK: - DEEP COPY
    class func selectedUniqueAttributesForEntity (entityName:String) -> [String]? {
        
        // Return an array of attribute names to be considered unique for an entity.
        // Multiple unique attributes are supported.
        // Only use attributes whose values are alphanumeric.
        
        switch (entityName) {
        case "Item"          :return ["name"]
        case "Item_Photo"    :return ["data"]
        case "Unit"          :return ["name"]
        case "LocationAtHome":return ["storedIn"]
        case "LocationAtShop":return ["aisle"]
        default:
            break;
        }
        return nil
    }
    
    class func objectInfo (object:NSManagedObject) -> String {
        
        if let entityName = object.entity.name {
            
            var attributes:NSString = ""
            
            if let uniqueAttributes = CDImporter.selectedUniqueAttributesForEntity(entityName: entityName) {
                
                for attribute in uniqueAttributes {
                    if let valueForKey = object.value(forKey: attribute) as? NSObject {
                        attributes = "\(attributes)\(attribute) \(valueForKey) " as NSString
                    }
                }
                
                // trim trailing space
                attributes = attributes.trimmingCharacters(in: NSCharacterSet.whitespaces) as NSString
                
                return "\(entityName) with \(attributes)"
            } else {print("ERROR: \(#function) could not find any uniqueAttributes")}
        } else {print("ERROR: \(#function) could not find an entityName")}
        
        return ""
    }
    
    class func copyUniqueObject (sourceObject:NSManagedObject, targetContext:NSManagedObjectContext) -> NSManagedObject? {
        
        if let entityName = sourceObject.entity.name {
            
            if let uniqueAttributes = CDImporter.selectedUniqueAttributesForEntity(entityName: entityName) {
                
                // PREPARE unique attributes to copy
                var uniqueAttributesFromSource:[String:AnyObject] = [:]
                for uniqueAttribute in uniqueAttributes {
                    uniqueAttributesFromSource[uniqueAttribute] = sourceObject.value(forKey: uniqueAttribute) as AnyObject
                }
                
                // PREPARE additional attributes to copy
                var additionalAttributesFromSource:[String:AnyObject] = [:]
                if let attributesByName:[String:AnyObject] = sourceObject.entity.attributesByName {
                    for (additionalAttribute, _) in attributesByName {
                        additionalAttributesFromSource[additionalAttribute] = sourceObject.value(forKey: additionalAttribute) as AnyObject
                    }
                }
                
                // COPY attributes to new object
                let copiedObject = CDOperation.insertUniqueObject(entityName: entityName, context: targetContext, uniqueAttributes: uniqueAttributesFromSource, additionalAttributes: additionalAttributesFromSource)
                
                return copiedObject
            } else {print("ERROR: \(#function) could not find any selected unique attributes for the '\(entityName)' entity")}
        } else {print("ERROR: \(#function) could not find an entity name for the given object '\(sourceObject)'")}
        return nil
    }
    
    class func establishToOneRelationship (relationshipName:String,from object:NSManagedObject, to relatedObject:NSManagedObject) {
        // SKIP establishing an existing relationship
        if object.value(forKey: relationshipName) != nil {
            print("SKIPPED \(#function) because the relationship already exists")
            return
        }
        
        if let targetContext = object.managedObjectContext {
            
            // ESTABLISH the relationship
            object.setValue(relatedObject, forKey: relationshipName)
            print("    A copy of \(CDImporter.objectInfo(object: object)) is related via To-One \(relationshipName) relationship to \(CDImporter.objectInfo(object: relatedObject))")
            
            // REMOVE the relationship from memory after it is committed to disk
            CDHelper.save(moc: targetContext)
            targetContext.refresh(object, mergeChanges: false)
            targetContext.refresh(relatedObject, mergeChanges: false)
        } else {print("ERROR: \(#function) could not get a targetContext")}
    }
    
    class func establishToManyRelationship (relationshipName:String,from object:NSManagedObject, sourceSet:NSMutableSet) {
        // SKIP establishing an existing relationship
        if object.value(forKey: relationshipName) != nil {
            print("SKIPPED \(#function) because the relationship already exists")
            return
        }
        
        if let targetContext = object.managedObjectContext {
            
            let targetSet = object.mutableSetValue(forKey: relationshipName)
            
            targetSet.enumerateObjects({ (relatedObject, stop) -> Void in
                
                if let theRelatedObject = relatedObject as? NSManagedObject {
                    
                    if let copiedRelatedObject = CDImporter.copyUniqueObject(sourceObject: theRelatedObject, targetContext: targetContext) {
                        
                        targetSet.add(copiedRelatedObject)
                        print("    A copy of \(CDImporter.objectInfo(object: object)) is related via To-Many \(relationshipName) relationship to \(CDImporter.objectInfo(object: copiedRelatedObject))")
                        
                        // REMOVE the relationship from memory after it is committed to disk
                        CDHelper.save(moc: targetContext)
                        targetContext.refresh(object, mergeChanges: false)
                        targetContext.refresh(theRelatedObject, mergeChanges: false)
                    } else {print("ERROR: \(#function) could not get a copiedRelatedObject")}
                } else {print("ERROR: \(#function) could not get theRelatedObject")}
            })
        } else {print("ERROR: \(#function) could not get a targetContext")}
    }
    
    class func establishOrderedToManyRelationship (relationshipName:String,from object:NSManagedObject, sourceSet:NSMutableOrderedSet) {
        
        // SKIP establishing an existing relationship
        if object.value(forKey: relationshipName) != nil {
            print("SKIPPED \(#function) because the relationship already exists")
            return
        }
        
        if let targetContext = object.managedObjectContext {
            
            let targetSet = object.mutableOrderedSetValue(forKey: relationshipName)
            
            targetSet.enumerateObjects { (relatedObject, index, stop) -> Void in
                
                if let theRelatedObject = relatedObject as? NSManagedObject {
                    
                    if let copiedRelatedObject = CDImporter.copyUniqueObject(sourceObject: theRelatedObject, targetContext: targetContext) {
                        
                        targetSet.add(copiedRelatedObject)
                        print("    A copy of \(CDImporter.objectInfo(object: object)) is related via Ordered To-Many \(relationshipName) relationship to \(CDImporter.objectInfo(object: copiedRelatedObject))'")
                        
                        // REMOVE the relationship from memory after it is committed to disk
                        CDHelper.save(moc: targetContext)
                        targetContext.refresh(object, mergeChanges: false)
                        targetContext.refresh(theRelatedObject, mergeChanges: false)
                    } else {print("ERROR: \(#function) could not get a copiedRelatedObject")}
                } else {print("ERROR: \(#function) could not get theRelatedObject")}
            }
        } else {print("ERROR: \(#function) could not get a targetContext")}
    }
    
    class func copyRelationshipsFromObject(sourceObject:NSManagedObject, to targetContext:NSManagedObjectContext) {
        if let copiedObject = CDImporter.copyUniqueObject(sourceObject: sourceObject, targetContext: targetContext) {
            
            let relationships = sourceObject.entity.relationshipsByName // [String : NSRelationshipDescription]
            
            for (_, relationship) in relationships {
                
                if relationship.isToMany && relationship.isOrdered {
                    
                    // COPY To-Many Ordered Relationship
                    let sourceSet = sourceObject.mutableOrderedSetValue(forKey: relationship.name)
                    CDImporter.establishOrderedToManyRelationship(relationshipName: relationship.name, from: copiedObject, sourceSet: sourceSet)
                    
                } else if relationship.isToMany && relationship.isOrdered == false {
                    
                    // COPY To-Many Relationship
                    let sourceSet = sourceObject.mutableSetValue(forKey: relationship.name)
                    CDImporter.establishToManyRelationship(relationshipName: relationship.name, from: copiedObject, sourceSet: sourceSet)
                    
                } else {
                    
                    // COPY To-One Relationship
                    if let relatedSourceObject = sourceObject.value(forKey: relationship.name) as? NSManagedObject {
                        
                        if let relatedCopiedObject = CDImporter.copyUniqueObject(sourceObject: relatedSourceObject, targetContext: targetContext) {
                            
                            CDImporter.establishToOneRelationship(relationshipName: relationship.name, from: copiedObject, to: relatedCopiedObject)
                            
                        } else {print("ERROR: \(#function) could not get a relatedCopiedObject")}
                    } else {print("ERROR: \(#function) could not get a relatedSourceObject")}
                }
            }
        } else {
            print("ERROR: \(#function) could not find or create an object to copy relationships to.")
            
        }
    }
    
    class func deepCopyEntities(entities:[String], from sourceContext:NSManagedObjectContext, to targetContext:NSManagedObjectContext) {
        for entityName in entities {
            print("DEEP COPYING '\(entityName)' objects to target context...")
            if let sourceObjects = CDOperation.objectsForEntity(entityName: entityName, context: sourceContext, filter: nil, sort: nil) as? [NSManagedObject] {
                
                for sourceObject in sourceObjects {
                    print("DEEP COPYING OBJECT: \(CDImporter.objectInfo(object: sourceObject))")
                    _ = CDImporter.copyUniqueObject(sourceObject: sourceObject, targetContext: targetContext)
                    CDImporter.copyRelationshipsFromObject(sourceObject: sourceObject, to: targetContext)
                }
            } else {print("ERROR: \(#function) could not find any sourceObjects")}
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
        }
    }
    
    class func triggerDeepCopy (sourceContext:NSManagedObjectContext, targetContext:NSManagedObjectContext, mainContext:NSManagedObjectContext) {
        
        sourceContext.perform {
            CDImporter.deepCopyEntities(entities: ["Item","Unit","LocationAtHome", "LocationAtShop"], from: sourceContext, to: targetContext)
            
            mainContext.perform {
                // Trigger interface refresh
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
            }
            
            print("*** FINISHED DEEP COPY FROM DEFAULT DATA PERSISTENT STORE ***")
        }
    }
}

