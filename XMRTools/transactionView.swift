//
//  transactionView.swift
//  XMR Tools
//
//  Created by John Lasseter on 10/29/17.
//  Copyright © 2017 Lasseter Productions. All rights reserved.
//

import Foundation
import UIKit

class transactionView: UIViewController {

    @IBOutlet weak var message: UITextView!
    
    @objc var uuid = "Default"
    @objc var responseSTR = "Loading..."
    @objc var timer = Timer()
    
    @objc func stringFromAny(_ value:Any?) -> String {
        if let nonNil = value, !(nonNil is NSNull) {
            return String(describing: nonNil)
        }
        return ""
    }
    
    @objc func updateDisplay() {
        self.message.text = responseSTR
    }
    
    @objc func getData(completion: @escaping (String) -> ()) {
        let Url = String(format: "https://xmr.to/api/v2/xmr2btc/order_status_query/")
        guard let serviceUrl = URL(string: Url) else { return }
        
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        let POST_uuid = "{\"uuid\": \"" + self.uuid + "\"}"
        
        let postString = POST_uuid
        
        request.httpBody = postString.data(using: .utf8)
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            let httpStatus = response as? HTTPURLResponse
            
            var i = Int()
            i = httpStatus!.statusCode
            
            //Success
            if (i == 200) {
                
                if let data = data {
                    do {
                        
                        if let parsedData = try? JSONSerialization.jsonObject(with: data) as! [String:Any] {
                            
                            let state                              = self.stringFromAny(parsedData["state"])
                            let uuid                               = self.uuid
                            let address                            = self.stringFromAny(parsedData["btc_dest_address"])
                            
                            let btc_amt                            = self.stringFromAny(parsedData["btc_amount"])
                            let btc_num_confirmations              = self.stringFromAny(parsedData["btc_num_confirmations"])
                            let btc_num_confirmations_before_purge = self.stringFromAny(parsedData["btc_num_confirmations_before_purge"])
                            let btc_transaction_id                 = self.stringFromAny(parsedData["btc_transaction_id"])
                            
                            let xmr_amount_total                   = self.stringFromAny(parsedData["xmr_amount_total"])
                            let xmr_amount_remaining               = self.stringFromAny(parsedData["xmr_amount_remaining"])
                            let xmr_price_btc                      = self.stringFromAny(parsedData["xmr_price_btc"])
                            
                            let xmr_receiving_integrated_address   = self.stringFromAny(parsedData["xmr_receiving_integrated_address"])
                            let xmr_receiving_address              = self.stringFromAny(parsedData["xmr_receiving_address"])
                            let xmr_required_payment_id_long       = self.stringFromAny(parsedData["xmr_required_payment_id_long"])
                            let xmr_required_payment_id_short      = self.stringFromAny(parsedData["xmr_required_payment_id_short"])
                            let xmr_recommended_mixin              = self.stringFromAny(parsedData["xmr_recommended_mixin"])
                            
                            let created_at                         = self.stringFromAny(parsedData["created_at"])
                            let expires_at                         = self.stringFromAny(parsedData["expires_at"])
                            let seconds_till_timeout               = self.stringFromAny(parsedData["seconds_till_timeout"])
                            
                            let m =
                                    "State: " + state + "\n" +
                                    "Order created at: " + created_at  + "\n" +
                                    "Order expires at: " + expires_at  + "\n" +
                                    "Seconds until timeout: " + seconds_till_timeout + "\n\n" +
                                        
                                    "UUID: " + uuid  + "\n" +
                                    "Bitcoin amount: " + btc_amt  + "\n" +
                                    "Bitcoin address: " + address  + "\n\n" +
                                        
                                    "Bitcoin confirmations: " + btc_num_confirmations  + "\n" +
                                    "Bitcoin confirmations before purge: " + btc_num_confirmations_before_purge  + "\n" +
                                    "Bitcoin transaction ID: " + btc_transaction_id  + "\n\n" +
                                        
                                    "Total XMR: " + xmr_amount_total  + "\n" +
                                    "Waiting for (XMR): " + xmr_amount_remaining  + "\n" +
                                    "1 XMR in BTC: " + xmr_price_btc  + "\n\n" +
                                        
                                    "XMR recommended mixin: " + xmr_recommended_mixin + "\n" +
                                    "XMR integrated address: " + xmr_receiving_integrated_address  + "\n\n" +
                                    "XMR old address: " + xmr_receiving_address  + "\n\n" +
                                    "Old XMR payment ID: " + xmr_required_payment_id_long  + "\n\n" +
                                    "Integrated XMR payment ID: " + xmr_required_payment_id_short
                            
                          completion(m)
                        }
                    }
                }
            }
        }.resume()
    }
    
    @objc func scheduledTimerWithTimeInterval(){
        
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.updateDisplay), userInfo: nil, repeats: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scheduledTimerWithTimeInterval()
    
        self.navigationController?.navigationBar.tintColor = UIColor(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0, alpha: 1)

        self.title = "Transaction"
        
        let _ = self.getData(completion: {response in
            self.responseSTR = response
        })
        
        
    }
}
