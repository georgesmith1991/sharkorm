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
        
        cleanup()
        
        let c = SyncPerson()
        c.name = "Test record"
        c.age = 38
        c.commit()
        
        var pk = c.id
        
        XCTAssert(SharkSyncChange.query().count() == 2, "Failed to write the correct number of values into the Sync table.")
        XCTAssert(SharkSyncChange.query().where(withFormat: "path = %@ AND value = %@", withParameters: ["\(pk ?? "")/SyncPerson/name","text/DeTHe9x80Ri7RhdbSKzD41MDdm+XMvyrfNXlPJ3/Hgo="]).count() == 1, "Failed to write the correct number of values into the Sync table.")
        XCTAssert(SharkSyncChange.query().where(withFormat: "recordGroup = '3651d5b8eedf11cf5df538b8aa04b49f' AND action = 1", withParameters: []).count() == 2, "Failed to write the correct number of values into the Sync table.")
        
        c.commit(inGroup: "ballbag")
        
        // now check for the delete
        XCTAssert(SharkSyncChange.query().count() == 5, "Failed to write the correct number of values into the Sync table.")
        XCTAssert(SharkSyncChange.query().where(withFormat: "path = %@", withParameters: ["\(pk ?? "")/SyncPerson/__delete__"]).count() == 1, "Failed to write the correct number of values into the Sync table.")
        
        // get the updated pk
        pk = c.id
        XCTAssert(SharkSyncChange.query().where(withFormat: "path = %@ AND value = %@", withParameters: ["\(pk ?? "")/SyncPerson/name","text/DeTHe9x80Ri7RhdbSKzD41MDdm+XMvyrfNXlPJ3/Hgo="]).count() == 1, "Failed to write the correct number of values into the Sync table.")
        
    }
    
    func test_sync() {
        
        cleanup()
        
        let c = SyncPerson()
        c.name = "Test record"
        c.age = 38
        c.commit(inGroup: "testcase")
        
        // now startup the sync feature
        SharkSync.synchroniseNow()
        
        cleanup()
        
        SharkSync.addVisibilityGroup("testcase")
        // now startup the sync feature
        SharkSync.synchroniseNow()
        
        XCTAssert(SyncPerson.query().count() > 0, "Failed to sync previously recorded records")
        
        SyncPerson.query().fetch().removeAll()
        SharkSync.synchroniseNow()
        
        XCTAssert(SyncPerson.query().count() == 0, "Found records which should not be there")
        
        cleanup()
        SharkSync.synchroniseNow()
        XCTAssert(SyncPerson.query().count() == 0, "Sync'ed records which should not be there")

        
    }
    
}
