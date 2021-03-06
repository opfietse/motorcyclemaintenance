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
    //    var currentMotorcycle: Motorcycle? {
    //        get {
    //            return 3.0 * sideLength
    //        }
    //        set {
    //            sideLength = newValue / 3.0
    //        }
    //    }
    
    var currentMotorcycle: Motorcycle? = nil
    
    //    public func setC(mc: Motorcycle) {
    //        self.currentMotorcycle = mc
    //    }
    //
    // MARK: - CELL CONFIGURATION
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        cell.accessoryType = UITableViewCell.AccessoryType.none
        
        if let motorcycleMaintenance = self.frc.object(at: indexPath) as? MotorcycleMaintenance {
            if let textLabel = cell.textLabel {
                textLabel.text = motorcycleMaintenance.motorcycle!.registration! + " " + String(describing: (motorcycleMaintenance.creationDate)!)
            }

            if let subtitleLabel = cell.detailTextLabel {
                if let _remarks = motorcycleMaintenance.remarks {
                    subtitleLabel.text = _remarks
                } else {
                    subtitleLabel.text = "No remarks"
                }
            }
        }
    }
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("init MCM ...")
        
        // CDTableViewController subclass customization
        self.entity = "MotorcycleMaintenance"
        self.sort = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.fetchBatchSize = 25
        self.cellIdentifier = "MCMCell"
    }
    
    // MARK: - VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "MotorcycleMaintenance"
        
        if let _currentMotorcycle = currentMotorcycle {
            self.filter = NSPredicate(format: "%K == %@", "motorcycle.registration", _currentMotorcycle.registration!)
            self.navigationItem.title = _currentMotorcycle.registration! + " (\(_currentMotorcycle.motorcycleType?.model ?? "Unknown model"))"
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let a = segue.destination
        print(a)
        
        if let segeuIdentifier = segue.identifier {
            if segeuIdentifier == "mcToAddMcmTasksSegue" {
                let addMcmtvc: AddMotorcycleMaintanceViewController = a as! AddMotorcycleMaintanceViewController
                addMcmtvc.currentMotorcycle = currentMotorcycle!
            } else {
                var mcm: MotorcycleMaintenance? = nil
                
                if let cell = sender as? UITableViewCell {
                    let indexPath: IndexPath = self.tableView.indexPath(for: cell)!
                    mcm = self.frc.object(at: indexPath) as? MotorcycleMaintenance
                } else {
                    let i = IndexPath(row: 0, section: 0)
                    //            i.row = 0
                    //            i.section = 0
                    mcm = self.frc.object(at: i) as? MotorcycleMaintenance
                }
                
                let mcmttvc: MotorcycleMaintenanceTaskTableViewController = a as! MotorcycleMaintenanceTaskTableViewController
                mcmttvc.currentMotorcycleMaintenance = mcm!
                
                print(String(describing: mcm))
            }
        }
    }
}

