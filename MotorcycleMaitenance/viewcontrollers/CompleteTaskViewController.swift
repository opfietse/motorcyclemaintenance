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
        if let currentRemarks = currentMotorcycleMaintenanceTask?.remarks {
            remarksTextField.text = currentRemarks
        }

        if let currentMileage = currentMotorcycleMaintenanceTask?.mileage {
            mileageTextField.text = String(currentMileage)
        }

        if let currentCompletionDate = currentMotorcycleMaintenanceTask?.completionDate {
            completionDateTextField.text = DateUtil.formatDate(date: currentCompletionDate)
        } else {
            completionDateTextField.text = DateUtil.formatDate(date: Date())
        }
        
        completionDateTextField.delegate = self
        remarksTextField.delegate = self
        mileageTextField.delegate = self
        
        self.hideKeyboardWhenBackgroundIsTapped()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func completeTask(_ sender: Any) {
        currentMotorcycleMaintenanceTask?.completed = true
//        currentMotorcycleMaintenanceTask?.remarks = "hardcoded"
        CDHelper.save(moc: moc!)
        delegate!.completeTask(motorcycleMaintenanceTask: currentMotorcycleMaintenanceTask!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelCompletingTask(_ sender: Any) {
        self.hideKeyboard()
        // self.navigationController?.popViewController(animated: true);
        delegate!.cancelTaskCompletion()
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case remarksTextField: currentMotorcycleMaintenanceTask?.remarks = remarksTextField.text
        case completionDateTextField: currentMotorcycleMaintenanceTask?.completionDate = completionDate
        case mileageTextField: currentMotorcycleMaintenanceTask?.mileage = Int32(mileageTextField.text!)!
        default: print("Unknown field \(textField)")
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        switch textField {
        case remarksTextField: currentMotorcycleMaintenanceTask?.remarks = remarksTextField.text
        case completionDateTextField: currentMotorcycleMaintenanceTask?.completionDate = DateUtil.dateFromString(dateAsString: completionDateTextField.text!)
        case mileageTextField: currentMotorcycleMaintenanceTask?.mileage = Int32(mileageTextField.text!)!
        default: print("Unknown field \(textField)")
        }
    }
    
    func hideKeyboardWhenBackgroundIsTapped() {
        let tgr: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(hideKeyboard))
        tgr.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tgr)
    }
    
    @objc func hideKeyboard() {
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
