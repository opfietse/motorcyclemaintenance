//
//  CompleteTaskViewController.swift
//  MotorcycleMaitenance
//
//  Created by Mark Reuvekamp on 27/03/2018.
//  Copyright © 2018 Mark Reuvekamp. All rights reserved.
//

import UIKit
import CoreData

class CompleteTaskViewController: UIViewController, UITextFieldDelegate {
    var currentMotorcycleMaintenanceTask: MotorcycleMaintenanceTask?
    var delegate: CompleteTaskDelegate?
    var completionDate: Date?
    var moc: NSManagedObjectContext?
    
    @IBOutlet weak var completionDateTextField: UITextField!
    @IBOutlet weak var remarksTextField: UITextField!
    @IBOutlet weak var mileageTextField: UITextField!
    
    // MARK: - INITIALIZATION
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        completionDate = Date()
        completionDateTextField.text = completionDate?.description
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func completeTask(_ sender: Any) {
        CDHelper.save(moc: moc!)
        delegate!.completeTask(motorcycleMaintenanceTask: currentMotorcycleMaintenanceTask!)
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.hideKeyboard()
        self.navigationController?.popViewController(animated: true);
        delegate!.cancelTaskCompletion()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case remarksTextField: currentMotorcycleMaintenanceTask?.remarks = remarksTextField.text
        case completionDateTextField: currentMotorcycleMaintenanceTask?.completionDate = completionDate
        case mileageTextField: currentMotorcycleMaintenanceTask?.mileage = Int16(mileageTextField.text!)!
        default: print("Unknown field \(textField)")
        }
    }
    
//    - (IBAction)cancel:(id)sender {
//    if (debug==1) {
//    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
//    }
//
//    }
    
func hideKeyboardWhenBackgroundIsTapped() {
//    if (debug==1) {
//    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
//    }
    
    let tgr: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector(("hideKeyboard")))
    tgr.cancelsTouchesInView = false
    self.view.addGestureRecognizer(tgr)
    }
    
    func hideKeyboard() {
//    if (debug==1) {
//    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
//    }
    
    self.view.endEditing(true)
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
