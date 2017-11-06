//
//  history.swift
//  XMR Tools
//
//  Created by John Lasseter on 10/24/17.
//  Copyright © 2017 Lasseter Productions. All rights reserved.
//

import UIKit
import os.log

class history: NSObject, NSCoding{
    
    //MARK: Properties
    @objc var amt: String
    @objc var state: String
    @objc var uuid: String
    @objc var address: String
    
    //MARK: Archiving Paths
    @objc static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    @objc static let ArchiveURL = DocumentsDirectory.appendingPathComponent("history")
    
    //MARK: Types
    struct HistoryKey {
        static let amt = "0"
        static let state = "Default text"
        static let uuid = "1234567891011"
        static let address = "IAmTheDefaultAddressInitializer"
    }
    
    @objc init(amt: String, state: String, uuid: String, address: String) {
        self.amt = amt
        self.state = state
        self.uuid = uuid
        self.address = address
        
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(amt, forKey: HistoryKey.amt)
        aCoder.encode(state, forKey: HistoryKey.state)
        aCoder.encode(uuid, forKey: HistoryKey.uuid)
        aCoder.encode(address, forKey: HistoryKey.address)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let amt = aDecoder.decodeObject(forKey: HistoryKey.amt) as? String else {
            os_log("Unable to decode the amt for a history object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let state = aDecoder.decodeObject(forKey: HistoryKey.state) as? String else {
            os_log("Unable to decode the state for a history object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let uuid = aDecoder.decodeObject(forKey: HistoryKey.uuid) as? String else {
            os_log("Unable to decode the uuid for a history object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let address = aDecoder.decodeObject(forKey: HistoryKey.address) as? String else {
            os_log("Unable to decode the address for a history object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(amt: amt, state: state, uuid: uuid, address: address)
    }
    
}

