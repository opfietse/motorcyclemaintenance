//
//  CDTableViewController.swift
//  Groceries
//
//  Created by Tim Roadley on 2/10/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import UIKit
import CoreData

class CDTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchControllerDelegate/*, UISearchResultsUpdating*/ {
    
    //    func updateSearchResults(for searchController: UISearchController) {
    //        <#code#>
    //    }
    
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }    
    
    // MARK: - CELL CONFIGURATION
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        // Use self.frc.objectAtIndexPath(indexPath) to get an object specific to a cell in the subclasses
        print("Please override configureCell in \(#function)!")
    }
    
    // Override
    var entity = "MyEntity"
    var sort = [NSSortDescriptor(key: "myAttribute", ascending: true)]
    
    // Optionally Override
    var context = CDHelper.shared.context
    var filter:NSPredicate? = nil
    var cacheName:String? = nil
    var sectionNameKeyPath:String? = nil
    var fetchBatchSize = 0 // 0 = No Limit
    var cellIdentifier = "Cell"
    var fetchLimit = 0
    var fetchOffset = 0
    var resultType:NSFetchRequestResultType = NSFetchRequestResultType.managedObjectResultType
    var propertiesToGroupBy:[AnyObject]? = nil
    var havingPredicate:NSPredicate? = nil
    var includesPropertyValues = true
    var relationshipKeyPathsForPrefetching:[AnyObject]? = nil
    
    // MARK: - FETCHED RESULTS CONTROLLER
    lazy var frc: NSFetchedResultsController = { () -> NSFetchedResultsController<NSFetchRequestResult> in
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:self.entity)
        request.sortDescriptors = self.sort
        request.fetchBatchSize  = self.fetchBatchSize
        if let _filter = self.filter {request.predicate = _filter}
        
        request.fetchLimit = self.fetchLimit
        request.fetchOffset = self.fetchOffset
        request.resultType = self.resultType
        request.includesPropertyValues = self.includesPropertyValues
        if let _propertiesToGroupBy = self.propertiesToGroupBy {request.propertiesToGroupBy = _propertiesToGroupBy}
        if let _havingPredicate = self.havingPredicate {request.havingPredicate = _havingPredicate}
        if let _relationshipKeyPathsForPrefetching = self.relationshipKeyPathsForPrefetching as? [String] {
            request.relationshipKeyPathsForPrefetching = _relationshipKeyPathsForPrefetching}
        
        let newFRC = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: self.context,
            sectionNameKeyPath: self.sectionNameKeyPath,
            cacheName: self.cacheName)
        newFRC.delegate = self
        return newFRC
    }()
    
    // MARK: - FETCHING
    func performFetch () {
        self.frc.managedObjectContext.perform ({
            
            do {
                try self.frc.performFetch()
            } catch {
                print("\(#function) FAILED : \(error)")
            }
            
            self.tableView.reloadData()
        })
    }
    
    // MARK: - VIEW
    override func viewDidLoad() {
        super.viewDidLoad()
        // Force fetch when notified of significant data changes
        NotificationCenter.default.addObserver(self, selector: Selector(("performFetch")), name: NSNotification.Name(rawValue: "SomethingChanged"), object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - DEALLOCATION
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "performFetch"), object: nil)
    }
    
    // MARK: - DATA SOURCE: UITableView
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.frc.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let i = self.frc.sections![section].numberOfObjects
        
        if (i == 0) {
            createRecords()
        }
        
        return i
    }
    
    func createRecords() {
        let mct: MotorcycleType = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleType", into: CDHelper.shared.context) as? MotorcycleType)!
        mct.make = "Moto Guzzi"
        mct.model = "Bellagio"
        mct.year = 2009
        
        let mc: Motorcycle = (NSEntityDescription.insertNewObject(forEntityName: "Motorcycle", into: CDHelper.shared.context) as? Motorcycle)!
        mc.motorcycleType = mct
        mc.registration = "MG-enzovoort"
        
        let mcm: MotorcycleMaintenance = (NSEntityDescription.insertNewObject(forEntityName: "MotorcycleMaintenance", into: CDHelper.shared.context) as? MotorcycleMaintenance)!
        mcm.creationDate = Date()
        mcm.motorcycle = mc
        
        CDHelper.saveSharedContext()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: self.cellIdentifier)
        }
        cell!.selectionStyle = UITableViewCellSelectionStyle.none
        cell!.accessoryType = UITableViewCellAccessoryType.detailButton
        self.configureCell(cell: cell!, atIndexPath: indexPath)
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.frc.section(forSectionIndexTitle: title, at: index)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.frc.sections![section].name
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.frc.sectionIndexTitles
    }
    
    // MARK: - DELEGATE: NSFetchedResultsController
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
        case .delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath! as IndexPath], with: .fade)
        case .delete:
            self.tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
        case .update:
            self.tableView.reloadRows(at: [indexPath! as IndexPath], with: .none)
        case .move:
            self.tableView.deleteRows(at: [indexPath! as IndexPath], with: .fade)
            self.tableView.insertRows(at: [newIndexPath! as IndexPath], with: .fade)
        }
    }    
    
    // MARK: - SEARCH
    var searchController:UISearchController? = nil
    
    func reloadFRC (predicate:NSPredicate?) {
        self.filter = predicate
        self.frc.fetchRequest.predicate = predicate
        self.performFetch()
    }
    
    func configureSearch () {
        self.searchController = UISearchController(searchResultsController: nil)
        if let _searchController = self.searchController {
            
            _searchController.delegate = self
            _searchController.searchResultsUpdater = self as? UISearchResultsUpdating
            _searchController.dimsBackgroundDuringPresentation = false
            _searchController.searchBar.delegate = self
            _searchController.searchBar.sizeToFit()
            self.tableView.tableHeaderView = _searchController.searchBar
            
        } else {print("ERROR configuring _searchController in %@", #function)}
    }
    
    // MARK: - DELEGATE: UISearchController
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        if let searchBarText = searchController.searchBar.text {
            
            var predicate:NSPredicate?
            if searchBarText != "" {
                predicate = NSPredicate(format: "name contains[cd] %@", searchBarText)
            }
            self.reloadFRC(predicate: predicate)
        }
    }
    
    // MARK: - DELEGATE: UISearchBar
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.reloadFRC(predicate: nil)
    }
}
