//
//  BaseSwiftTest.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 08/11/2017.
//  Copyright © 2017 Adrian Herridge. All rights reserved.
//

import Foundation
import XCTest

class BaseSwiftTest : XCTestCase, SRKDelegate {
    
    override func setUp() {
        super.setUp()
        SharkORM.setDelegate(self)
        SharkORM.openDatabaseNamed("swift-test")
    }
    
    override func tearDown() {
        SharkORM.closeDatabaseNamed("swift-test")
        SharkORM.setDelegate(nil)
        super.tearDown()
    }
    
}
