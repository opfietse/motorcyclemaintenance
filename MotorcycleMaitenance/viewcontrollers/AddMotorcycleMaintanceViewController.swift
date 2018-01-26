//
//  AddMotorcycleMaintanceViewController.swift
//  MotorcycleMaitenance
//
//  Created by Mark Reuvekamp on 09/01/2018.
//  Copyright © 2018 Mark Reuvekamp. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class AddMotorcycleMaintanceViewController: UIViewController {
    var currentMotorcycle: Motorcycle? = nil
    let context = CDHelper.shared.context

    @IBOutlet weak var registrationTextField: UITextField!
    
    @IBOutlet weak var errorTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        registrationTextField.text = currentMotorcycle?.registration ?? nil
        
//        if let managedObjectContext = context {
            // Add Observer
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
//            notificationCenter.addObserver(self, selector: #selector(managedObjectContextWillSave), name: NSManagedObjectContextWillSaveNotification, object: context)
//        notificationCenter.addObserver(self, selector: #selector(context), name: NSManagedObjectContextDidSaveNotification, object: managedObjectContext)
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction
    func createMotorcycleMaintenance(sender: AnyObject) {
        print("Create mcm .......")
        errorTextField.text = "Fetching tasks ..."
        
        if let registration = registrationTextField.text {
            if let motorcycle = self.fetchMotorcycle(registration: registration) {
                let motorcycleType = motorcycle.motorcycleType
                
                let tasksForMotorcycleType = self.fetchMotorcycleTypeMaintenanceTask(motorcycleType: motorcycleType!)
                errorTextField.text = "Found \(tasksForMotorcycleType.count) tasks"
                
                let motorcycleMaintenance: MotorcycleMaintenance = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleMaintenance", into: context) as? MotorcycleMaintenance)!
                motorcycleMaintenance.motorcycle = currentMotorcycle
                motorcycleMaintenance.creationDate = Date()
//                motorcycleMaintenance1.startDate = motorcycleMaintenance.startDate
//                motorcycleMaintenance1.endDate = motorcycleMaintenance.endDate
//                motorcycleMaintenance1.remarks = motorcycleMaintenance.remarks

                CDHelper.save(moc: context)

                // Add tasks
                for taskForMotorcycleType in tasksForMotorcycleType {
                 let motorcycleMaintenanceTask: MotorcycleMaintenanceTask = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleMaintenanceTask", into: context) as? MotorcycleMaintenanceTask)!
                 
                 motorcycleMaintenanceTask.motorcycleMaintenance = motorcycleMaintenance
                 motorcycleMaintenanceTask.motorcycleTypeMaintenanceTask = taskForMotorcycleType
                 motorcycleMaintenanceTask.completionDate = nil//mcTask.completionDate
                 motorcycleMaintenanceTask.mileage = 0 // mcTask.mileage
                 motorcycleMaintenanceTask.remarks = nil //mcTask.remarks

                    /*

                 
                    let motorcycleMaintenanceTask: MotorcycleMaintenanceTask = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleMaintenanceTask", into: context) as? MotorcycleMaintenanceTask)!
                    
                    motorcycleMaintenanceTask.motorcycleMaintenance = motorcycleMaintenance
                    motorcycleMaintenanceTask.motorcycleTypeMaintenanceTask = taskForMotorcycleType
                    motorcycleMaintenance.addToMotorcycleMaintenanceTasks(motorcycleMaintenanceTask)
//                    motorcycleMaintenanceTask1.completionDate = mcTask.completionDate
//                    motorcycleMaintenanceTask1.mileage = mcTask.mileage
//                    motorcycleMaintenanceTask1.remarks = mcTask.remarks
                     */

//                    CDHelper.save(moc: context)
                }
                CDHelper.save(moc: context)
            } else {
                errorTextField.text = "Motorcycle not found!"
            }
        } else {
            errorTextField.text = "No registration given!"
        }
    }
    
    func fetchMotorcycle(registration: String) -> Motorcycle? {
        let motorcyclesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Motorcycle")
        
        let registrationPredicate = NSPredicate(format: "registration == %@", registration)
        
        motorcyclesFetch.predicate = registrationPredicate
        
        do {
            let fetchedMotorcycles = try context.fetch(motorcyclesFetch) as! [Motorcycle]
            
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
    
    
    func fetchMotorcycleTypeMaintenanceTask(motorcycleType: MotorcycleType) -> [MotorcycleTypeMaintenanceTask] {
        let motorcycleTypeMaintenanceTasksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "MotorcycleTypeMaintenanceTask")
        
        let mcTypePredicate = NSPredicate(format: "motorcycleType == %@", motorcycleType)
        let motorcycleTypeMaintenanceTaskPredicate = mcTypePredicate
        
        motorcycleTypeMaintenanceTasksFetch.predicate = motorcycleTypeMaintenanceTaskPredicate
        
        do {
            let motorcycleTypeMaintenanceTasks = try context.fetch(motorcycleTypeMaintenanceTasksFetch) as! [MotorcycleTypeMaintenanceTask]
            
            return motorcycleTypeMaintenanceTasks
        } catch {
            fatalError("Failed to fetch MotorcycleTypeMaintenanceTask: \(error)")
        }
    }

    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
//        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> where inserts.count > 0 {
//            print("--- INSERTS ---")
//            print(inserts)
//            print("+++++++++++++++")
//        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            print("--- UPDATES ---")
            for update in updates {
                print(update.changedValues())
            }
            print("+++++++++++++++")
        }
        
//        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> where deletes.count > 0 {
//            print("--- DELETES ---")
//            print(deletes)
//            print("+++++++++++++++")
//        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
