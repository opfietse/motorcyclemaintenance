//
//  MotorcycleMaintenance.swift
//  MotorcycleMaitenance
//
//  Created by Mark Reuvekamp on 12/11/2017.
//  Copyright © 2017 Mark Reuvekamp. All rights reserved.
//

import UIKit
import CoreData

class MotorcycleMaintenanceTableViewController: CDTableViewController {
    
    // MARK: - CELL CONFIGURATION
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        cell.accessoryType = UITableViewCellAccessoryType.none
        
        if let motorcycleMaintenance = self.frc.object(at: indexPath) as? MotorcycleMaintenance {
            if let textLabel = cell.textLabel {
                textLabel.text = motorcycleMaintenance.motorcycle!.registration! + " " + String(describing: (motorcycleMaintenance.creationDate)!)
            }
        }
    }
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // CDTableViewController subclass customization
        self.entity = "MotorcycleMaintenance"
        self.sort = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.fetchBatchSize = 25
    }
    
    // MARK: - VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "MotorcycleMaintenance"
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

