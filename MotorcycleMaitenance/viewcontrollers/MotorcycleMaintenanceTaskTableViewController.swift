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
                textLabel.text = motorcycleMaintenanceTask.motorcycleTypeMaintenanceTask?.task?.taskDescription
            }
            
            if let subtitleLabel = cell.detailTextLabel {
                if (motorcycleMaintenanceTask.completed) {
                    cell.textLabel?.textColor = UIColor.green
                    
                    if let _completionDate = motorcycleMaintenanceTask.completionDate {
                        subtitleLabel.text = "Completed at \(_completionDate) \(motorcycleMaintenanceTask.remarks ?? "")"
                    } else {
                        let now = Date()
                        motorcycleMaintenanceTask.completionDate = now
                        subtitleLabel.text = "Completed at \(now) \(motorcycleMaintenanceTask.remarks ?? "")"
                    }
                } else {
                    cell.textLabel?.textColor = UIColor.black
                    subtitleLabel.text = ""
                }
            }
        }
    }
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("init MCMT ...")
        
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
            self.filter = NSPredicate(format: "%K == %@", "motorcycleMaintenance", _currentMotorcycleMaintenance)
            
            var formattedCreationDate: String
            
            if let creationDate = _currentMotorcycleMaintenance.creationDate {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "nl_NL")
                dateFormatter.setLocalizedDateFormatFromTemplate("dd-MM-yyyy")
                formattedCreationDate = dateFormatter.string(from: creationDate)
            } else {
                formattedCreationDate = "Date unknown"
            }
            self.navigationItem.title = (_currentMotorcycleMaintenance.motorcycle?.registration)! + " " + formattedCreationDate
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let motorcycleMaintenanceTask = self.frc.object(at: indexPath) as? MotorcycleMaintenanceTask {
            motorcycleMaintenanceTask.completed = !motorcycleMaintenanceTask.completed;
        }

        self.performFetch()
    }
    
    // MARK: - INTERACTION
    @IBAction func done (sender: AnyObject) {
        
        if let parent = self.parent {
            parent.dismiss(animated: true, completion: nil)
        }
    }
}


