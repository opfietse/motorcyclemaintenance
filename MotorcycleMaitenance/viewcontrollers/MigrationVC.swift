//
//  MigrationVC.swift
//  Groceries
//
//  Created by Tim Roadley on 30/09/2015.
//  Copyright © 2015 Tim Roadley. All rights reserved.
//

import UIKit

class MigrationVC: UIViewController {

    @IBOutlet var label: UILabel!
    @IBOutlet var progressView: UIProgressView!    

    // MARK: - MIGRATION
    func progressChanged (note:AnyObject?) {
        if let _note = note as? NSNotification {
            if let progress = _note.object as? NSNumber {
                let progressFloat:Float = round(progress.floatValue * 100)
                let text = "Migration Progress: \(progressFloat)%"
                print(text)

                DispatchQueue.main.async(execute: {
                    self.label.text = text
                    self.progressView.progress = progress.floatValue
                })
            } else {print("\(#function) FAILED to get progress")}
        } else {print("\(#function) FAILED to get note")}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: Selector(("progressChanged:")), name: NSNotification.Name(rawValue: "migrationProgress"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "migrationProgress"), object: nil)
    }
}
