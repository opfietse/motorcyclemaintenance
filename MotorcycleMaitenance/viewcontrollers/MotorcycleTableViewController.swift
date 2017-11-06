//
//  LocationsAtHomeTVC.swift
//  Groceries
//
//  Created by Tim Roadley on 21/07/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import UIKit
import CoreData

class MotorcycleTableViewController: CDTableViewController {
    
    // MARK: - CELL CONFIGURATION
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        cell.accessoryType = UITableViewCellAccessoryType.none
        
        if let locationAtHome = self.frc.objectAtIndexPath(indexPath) as? Motorcycle {
            if let textLabel = cell.textLabel {
                textLabel.text = locationAtHome.storedIn
            }
        }
    }
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // CDTableViewController subclass customization
        self.entity = "LocationAtHome"
        self.sort = [NSSortDescriptor(key: "storedIn", ascending: true)]
        self.fetchBatchSize = 25
    }
    
    // MARK: - VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Home Locations"
        self.performFetch()
    }
    
    // MARK: - DATA SOURCE: UITableView
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let object = self.frc.objectAtIndexPath(indexPath) as? NSManagedObject {
            self.frc.managedObjectContext.deleteObject(object)
        }
        CDHelper.saveSharedContext()
    }
    
    // MARK: - INTERACTION
    @IBAction func done (sender: AnyObject) {
        
        if let parent = self.parent {
            parent.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - SEGUE
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let locationAtHomeVC = segue.destinationViewController as? LocationAtHomeVC {
        
            if segue.identifier == "Add Object Segue" {
            
                let object = NSEntityDescription.insertNewObject(forEntityName: "LocationAtHome", into: CDHelper.shared.context)
                locationAtHomeVC.segueObject = object
                
            } else if segue.identifier == "Edit Object Segue" {
                
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    if let object = self.frc.objectAtIndexPath(indexPath) as? NSManagedObject {
                        locationAtHomeVC.segueObject = object
                    }
                }
            } else {print("Unidentified Segue Attempted!")}
        }
    }
}
