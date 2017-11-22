//
//  MotorcycleMaintenanceTaskTableViewController.swift
//  MotorcycleMaitenance
//
//  Created by Mark Reuvekamp on 20/11/2017.
//  Copyright © 2017 Mark Reuvekamp. All rights reserved.
//

import UIKit
import CoreData

class MotorcycleMaintenanceTaskTableViewController: CDTableViewController {
    var currentMotorcycleMaintenance: MotorcycleMaintenance?
    
    // MARK: - CELL CONFIGURATION
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        cell.accessoryType = UITableViewCellAccessoryType.none
        
        if let motorcycleMaintenanceTask = self.frc.object(at: indexPath) as? MotorcycleMaintenanceTask {
            if let textLabel = cell.textLabel {
                textLabel.text = String(motorcycleMaintenanceTask.milage) + " " + String(describing: (motorcycleMaintenanceTask.completionDate)!)
            }
        }
    }

    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // CDTableViewController subclass customization
        self.entity = "MotorcycleMaintenanceTask"
        self.sort = [NSSortDescriptor(key: "completionDate", ascending: false)]
        self.fetchBatchSize = 25
        self.cellIdentifier = "MCMTCell"
    }
    
    // MARK: - VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "MotorcycleMaintenanceTask"
        
        if let _currentMotorcycleMaintenance = currentMotorcycleMaintenance {
            self.filter = NSPredicate(format: "%K == %@", "motorcycleMaintenance.motorcycle.registration", _currentMotorcycleMaintenance.motorcycle!.registration!)
        } else {
            self.filter = nil
        }

        self.performFetch()
    }
    
    // MARK: - DATA SOURCE: UITableView
    //    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    //
    //        if let object = self.frc.object(at: indexPath as IndexPath) as? NSManagedObject {
    //            self.frc.managedObjectContext.delete(object)
    //        }
    //
    //        CDHelper.saveSharedContext()
    //    }
    
    // MARK: - INTERACTION
    @IBAction func done (sender: AnyObject) {
        
        if let parent = self.parent {
            parent.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - SEGUE
    //    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    //        if let locationAtHomeVC = segue.destinationViewController as? LocationAtHomeVC {
    //
    //            if segue.identifier == "Add Object Segue" {
    //
    //                let object = NSEntityDescription.insertNewObject(forEntityName: "LocationAtHome", into: CDHelper.shared.context)
    //                locationAtHomeVC.segueObject = object
    //
    //            } else if segue.identifier == "Edit Object Segue" {
    //
    //                if let indexPath = self.tableView.indexPathForSelectedRow {
    //                    if let object = self.frc.objectAtIndexPath(indexPath) as? NSManagedObject {
    //                        locationAtHomeVC.segueObject = object
    //                    }
    //                }
    //            } else {print("Unidentified Segue Attempted!")}
    //        }
    //    }
}


