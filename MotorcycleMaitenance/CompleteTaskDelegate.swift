//
//  CompleteTaskDelegate.swift
//  MotorcycleMaitenance
//
//  Created by Mark Reuvekamp on 08/04/2018.
//  Copyright © 2018 Mark Reuvekamp. All rights reserved.
//

import Foundation

protocol CompleteTaskDelegate {
    func completeTask(motorcycleMaintenanceTask: MotorcycleMaintenanceTask)
    func cancelTaskCompletion()
}
