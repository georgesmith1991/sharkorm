//
//  LocalRecordCreation.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 08/11/2017.
//  Copyright © 2017 Adrian Herridge. All rights reserved.
//

import Foundation
import XCTest

class Sync : BaseSwiftTest {
    
    func test_local_record_creation() {
        
        SharkSyncChange.query().fetch().removeAll()
        
        let c = SyncPerson()
        c.name = "Test record"
        c.age = 38
        c.commit()
        
        let count = SharkSyncChange.query().count()
        
        print("finished test")
        
    }
    
}
