//
//  ViewController.swift
//  XMR Tools
//
//  Created by John Lasseter on 10/19/17.
//  Copyright © 2017 Lasseter Productions. All rights reserved.
//

import UIKit
import Foundation
import os.log

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate{

    //MARK: Properties and misc
    @IBOutlet weak var addressToPayField: UITextField!
    @IBOutlet weak var btcToPayField: UITextField!
    
    @IBOutlet weak var priceMessage: UILabel!
    @IBOutlet weak var limitsMessage: UILabel!
    @IBOutlet weak var instantMessage: UILabel!
 
    @IBOutlet weak var tableView: UITableView!
    
    @objc var histories = [history]()
    @objc var timer = Timer()
    @objc var conversion = String()
    @objc var upper_limit = String()
    @objc var lower_limit = String()
    @objc var zero_conf = String()
    @objc var zero_conf_max = String()
    @objc var tableViewTotal = 0
    @objc let cellReuseIdentifier = "cell"
    
    @objc var notify_POST_message = "Please try again."
    
    @objc var transaction_uuid = "Default"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Handle the text field’s user input through delegate callbacks.
        addressToPayField.delegate = self
        btcToPayField.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateMainHistory), name: NSNotification.Name(rawValue: "updateMH"), object: nil)
        
        self.histories = self.loadHistory()!
    
        //MARK: Auto-update
        scheduledTimerWithTimeInterval()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        self.saveHistory()
    }
    
    //MARK: Private Functions
    private func saveHistory() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(histories, toFile: history.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("History successfully saved.", log: OSLog.default, type: .debug)
            print(history.ArchiveURL.path)
        } else {
            os_log("Failed to save History...", log: OSLog.default, type: .error)
        }
        
    }
    
    private func loadHistory() -> [history]? {
        var t = NSKeyedUnarchiver.unarchiveObject(withFile: history.ArchiveURL.path) as? [history]
        
        if (t == nil) {
            t = [history]()
        }
        
        return t
        
    }
    
    //MARK: Public Functions
    @objc func updateMainHistory() {
        
        self.histories = [history]()
        DispatchQueue.main.async(execute: { () -> Void in
            self.tableView.reloadData()
        })

    }
    
    
    @objc func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateConversion" with the interval of 0.5 seconds
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateConversion), userInfo: nil, repeats: true)
    }
    
    @objc func stringFromAny(_ value:Any?) -> String {
        if let nonNil = value, !(nonNil is NSNull) {
            return String(describing: nonNil)
        }
        return ""
    }
    
    @objc func reloadMessages(str1:String, str2:String, str3:String) {
        
        self.priceMessage.text = str1
        self.limitsMessage.text = str2
        self.instantMessage.text = str3
    }
    
    @objc func updateConversion() {
        let Url = String(format: "https://xmr.to/api/v2/xmr2btc/order_parameter_query/")
        guard let serviceUrl = URL(string: Url) else { return }

        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "GET"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in if let data = data {
                do {
                    
                    if let parsedData = try? JSONSerialization.jsonObject(with: data) as! [String:Any] {
                        
                        if let price = parsedData["price"], let ll = parsedData["lower_limit"], let ul = parsedData["upper_limit"], let zc = parsedData["zero_conf_enabled"], let zcm = parsedData["zero_conf_max_amount"]{
                            
                            let tmp1 =
                                "Indicative price: " + self.stringFromAny(price) +  " XMR:BTC"
                            let tmp2 =
                                "Limits: " + self.stringFromAny(ll) + " - " + self.stringFromAny(ul) + " BTC"
                            let tmp3 =
                                "Instant confimation: " + ((self.stringFromAny(zc) == "1") ? "up to " + self.stringFromAny(zcm) + " BTC" : "disabled")
                            
                            DispatchQueue.main.async(execute: {
                                self.reloadMessages(str1: tmp1, str2: tmp2, str3:tmp3)
                            })
                            
                        } else {
                            DispatchQueue.main.async(execute: {
                                self.reloadMessages(str1: " ", str2: "Error loading. Retrying...", str3: " ")
                            })
                        }
                    }
                }
            }
        }.resume()
    }
    
    @objc func sendTransaction(completion: @escaping (String) -> ()) {
        let Url = String(format: "https://xmr.to/api/v2/xmr2btc/order_create/")
        guard let serviceUrl = URL(string: Url) else { return }
        
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        let btcSendAMT = "{\"btc_amount\": " + self.btcToPayField.text!
        let btcWalletToPay = "\"btc_dest_address\": " + "\"" + self.addressToPayField.text! + "\"}"
        
        let postString = btcSendAMT + " , " + btcWalletToPay
        
        request.httpBody = postString.data(using: .utf8)
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            let httpStatus = response as? HTTPURLResponse
            
            var i = Int()
            i = httpStatus!.statusCode
            
            //Success
            if (i == 201) {
            
                if let data = data {
                    do {
                        
                        if let parsedData = try? JSONSerialization.jsonObject(with: data) as! [String:Any] {
          
                            let amt = self.stringFromAny(parsedData["btc_amount"])
                            var state = self.stringFromAny(parsedData["state"])
                            if (state == "TO_BE_CREATED")
                            {
                                state = "Request"
                            }
                            let address = self.stringFromAny(parsedData["btc_dest_address"])
                            let uuid = self.stringFromAny(parsedData["uuid"])
                            
                            let tmp_hist = history(amt: amt, state: state, uuid: uuid, address: address)
                            
                            self.histories = [tmp_hist] + self.histories
                            self.saveHistory()
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                self.tableView.reloadData()
                            })
                        }
                    }
                }
            }
            completion(String(i))
            
            }.resume()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        // Hide the keyboard.
        textField.resignFirstResponder()
        
        //Always respond yes to enter/done
        return true;
    }
    
    //MARK: Actions
    
    
    @IBAction func sendRequest(_ sender: UIButton) {
        sendTransaction(completion: {httpResp in
            
            if (httpResp == "201") {
                
                let m = "Your transaction will be created."
                let t = "Success"
                
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(title: t, message: m, preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                })
            }
            //Services unavailable
            if (httpResp == "503") {
                
                let m = "Internal services unavailable or requested amount outside of limits: please try again later or check the limits"
                let t = "Failure"
                
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(title: t, message: m, preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                })
            }
            
            if (httpResp == "400") {
                
                let m = "Malformed Bitcoin address or amount: Please check input validity or contact xmr.to support"
                
                let t = "Failure"
                
                DispatchQueue.main.async(execute: {
                    
                    let alert = UIAlertController(title: t, message: m, preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                })
            }
        })
    }
    
    //MARK: Tableview
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.histories.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! HistoryTableViewCell
        
        // set the text from the data model
        cell.stateLabel.text = self.histories[indexPath.row].state
        cell.addressLabel.text = self.histories[indexPath.row].address
        cell.uuidLabel.text = self.histories[indexPath.row].uuid
        cell.amountLabel.text = self.histories[indexPath.row].amt
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = self.histories[indexPath.row]
        
        let txnView = self.storyboard?.instantiateViewController(withIdentifier: "transactionViewController") as! transactionView
        txnView.uuid = cell.uuid
        self.navigationController?.pushViewController(txnView, animated: true)
        
    }
}
