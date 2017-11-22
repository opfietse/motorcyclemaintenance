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
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        cell.accessoryType = UITableViewCellAccessoryType.none
        
        if let motorcycle = self.frc.object(at: indexPath) as? Motorcycle {
            if let textLabel = cell.textLabel {
                textLabel.text = motorcycle.registration! + " " + (motorcycle.motorcycleType?.make)! + " " + (motorcycle.motorcycleType?.model)!
            }
        }
    }
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // CDTableViewController subclass customization
        self.entity = "Motorcycle"
        self.sort = [NSSortDescriptor(key: "registration", ascending: true)]
        self.fetchBatchSize = 25
        self.cellIdentifier = "MCCell"
    }
    
    // MARK: - VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Motorcycles"
        self.performFetch()
    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        // pass any object as parameter, i.e. the tapped row
//        performSegue(withIdentifier: "mcToMcmSegue", sender: self.tableView.cellForRow(at: indexPath))
//    }
    
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
        print("Dest: " + String(describing: a))
        
        var mc: Motorcycle? = nil
        
        if let cell = sender as? UITableViewCell {
            let indexPath: IndexPath = self.tableView.indexPath(for: cell)!
            mc = self.frc.object(at: indexPath) as? Motorcycle
        } else {
            let i = IndexPath(row: 0, section: 0)
//            i.row = 0
//            i.section = 0
            mc = self.frc.object(at: i) as? Motorcycle
        }
        
        print(String(describing: mc))

        let mcmtvc: MotorcycleMaintenanceTableViewController = a as! MotorcycleMaintenanceTableViewController
        mcmtvc.currentMotorcycle = mc!
        
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
//                    if let object = self.frc.object(at: indexPath) as? NSManagedObject {
//                        locationAtHomeVC.segueObject = object
//                    }
//                }
//            } else {print("Unidentified Segue Attempted!")}
//        }
    }
}
