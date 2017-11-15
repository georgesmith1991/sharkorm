//
//  SyncObjects.swift
//  SharkORMTests
//
//  Created by Adrian Herridge on 08/11/2017.
//  Copyright © 2017 Adrian Herridge. All rights reserved.
//

import Foundation

class SyncPerson : SRKSyncObject {
    
    @objc dynamic var  name: String?
    @objc dynamic var  age: Int = 0
    
}
