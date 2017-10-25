//
//  SwiftTest.swift
//  SharkORM
//
//  Copyright © 2016 SharkSync. All rights reserved.
//

import Foundation

class PersonSwift : SRKObject {
    
    @objc internal dynamic var Name: String?
    @objc internal dynamic var age: NSNumber?
    @objc internal dynamic var department: DepartmentSwift?
    
}

class SmallPersonSwift : PersonSwift {
    
    @objc dynamic var height: NSNumber?
    
}

class DepartmentSwift : SRKObject {
    
    @objc dynamic var name: String?
    
}

class SwiftTestClass : SRKObject {
	
    @objc dynamic var SwiftNumber: NSNumber?
	@objc dynamic var SwiftTestString : String?
	@objc dynamic var SwiftTestNumber : NSNumber?
	@objc dynamic var lowercaseField : String?
    @objc dynamic var isdeleted : Bool = false
	var nonDynamicVariable : String?
    var testVar : Int?
    
    override init() {
        super.init()
    }
    
    init(defaultString: String?) {
        super.init()
        self.SwiftTestString = defaultString;
        self.nonDynamicVariable = defaultString;
    }
	
	func testThyself() {
		
	}
	
	class PrivateSwiftClass: SRKObject {
		
		@objc dynamic var SwiftTestString : String!
		@objc dynamic var SwiftTestNumber : NSNumber!
		
		func testThyself() {
		
            
		}
    
		
	}
    
    class func testInitialValues() {
        
        let p = Person(dictionary: ["Name" : "Adrian Herridge", "age" : 38])
        p?.commit()
        
    }
	
}
