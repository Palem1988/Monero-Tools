//
//  AboutView.swift
//  XMRTools
//
//  Created by John Lasseter on 11/1/17.
//  Copyright © 2017 Lasseter Productions. All rights reserved.
//

import Foundation
import UIKit
import os.log

class AboutView: UIViewController, UITextFieldDelegate {
    
    @IBAction func deleteHistory(_ sender: AnyObject) {
        
        let refreshAlert = UIAlertController(title: "Delete history?", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action: UIAlertAction!) in
            
            let fileManager = FileManager.default
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            guard let dirPath = paths.first else {
                return
            }
            
            let filePath = "\(dirPath)/history"
            do {
                try fileManager.removeItem(atPath: filePath)
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateMH"), object: nil)

            } catch let error as NSError {
                print(error.debugDescription)
            }
            
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            os_log("Delete history canceled", log: OSLog.default, type: .debug)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

}



