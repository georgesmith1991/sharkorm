//
//  BaseSwiftTest.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 08/11/2017.
//  Copyright © 2017 Adrian Herridge. All rights reserved.
//

import Foundation
import XCTest
//import SharkPrivate

class BaseSwiftTest : XCTestCase, SRKDelegate {
    
    override func setUp() {
        super.setUp()
        SharkORM.setDelegate(self)
        SharkORM.openDatabaseNamed("swift-test")
        SharkSync.initService(withApplicationId: "4532bd8a-7c8d-4e37-8e36-95548f29b7eb", apiKey: "681b8350-7f07-4953-a027-bba47e6a9d96")
    }
    
    override func tearDown() {
        SharkORM.closeDatabaseNamed("swift-test")
        SharkORM.setDelegate(nil)
        super.tearDown()
    }
    
    func cleanup() {
        // cleanup all the crazy local records
        SharkORM .executeSQL("DELETE FROM SRKSyncOptions;", inDatabase: nil)
        SharkORM .executeSQL("DELETE FROM SharkSyncChange;", inDatabase: nil)
        SharkORM .executeSQL("DELETE FROM SyncPerson;", inDatabase: nil)
        SharkORM .executeSQL("DELETE FROM SRKSyncGroup;", inDatabase: nil)
    }
    
}
