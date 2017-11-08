//    MIT License
//
//    Copyright (c) 2016 SharkSync
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import SharkSyncPrivate

enum SharkSyncOperation : Int {
    case Undefined = 0
    case Insert = 1
    case Update = 2
    case Delete = 3
}

class SyncRequest {
    
    var changes: [SharkSyncChange] = []
    var groups: [SRKSyncGroup] = []
    
    func requestObject() -> [String: Any] {
        
        var requestData: [String: Any] = [:]
        
        // pull out a reasonable amount of writes to be sent to the server
        let changeResults = (SharkSyncChange.query().limit(100).order(by: "timestamp").fetch()) as! [SharkSyncChange]
        self.changes = changeResults
        
        // now add in the changes, and the tidemarks
        var changes: [[String:Any]] = []
        
        for change: SharkSyncChange in changeResults {
            changes.append(["path": change.path ?? "",
                            "value": change.value ?? "",
                            "secondsAgo": (Date().timeIntervalSince1970 - (change.timestamp?.doubleValue)!),
                            "group": change.recordGroup ?? "",
                            "operation": change.action]
            )
        }
        
        requestData["changes"] = changes
        
        // now select out the data groups to poll for, oldest first
        let groupResults = SRKSyncGroup.query().limit(100).order(by: "last_polled").fetch() as! [SRKSyncGroup]
        self.groups = groupResults
        var groups: [[String:Any]] = []
        for group: SRKSyncGroup in groupResults {
            groups.append(["group": group.groupName ?? "", "tidemark": group.tidemark_uuid ?? NSNull()])
        }
        requestData["groups"] = groups
        return requestData
    }
    
    func requestResponded(_ response: [String: Any]) {
        
        /* clear down the transmitted data, as we know it arrived okay */
        self.changes.removeAll()
        
        // check for success/error
        if !((response["Success"] as? Bool) ?? false) {
            // there was an error from the service, so we need to bail at this point
            return
        }
        
        // check for sync_id which is out of step with our current stored data/
        /*
         *   NOTE: the sync id has changed, so we essentially, have to destroy the local data and re-sync with the server as the state is unknown.  E.g. Server data restored, corruption fixed, etc.  Not a common thing, only used in extreme scenarios.
         */
        
        if response["SyncID"] != nil {
            // TODO:  check and dump data
            //            if data?["sync_id"] != nil {
            //                let options = SRKSyncOptions.query().limit(1).fetch().first
            //                if options?.sync_id == nil {
            //                    options?.sync_id = data?["sync_id"]
            //                    options?.commit()
            //                }
            //                else {
            //                    if !options?.sync_id == data?["sync_id"] {
            //                        // clear the outbound
            //                        SharkSyncChange.query().fetchLightweight().removeAll()
            //                        // clear all the registered classes that have ever had any data
            //                        options?.device_id = UUID().uuidString
            //                        options?.commit()
            //                        return
            //                    }
            //                }
            //            }
        }
        
        /* now work through the response */
        for group in (response["Groups"] as? [[String:Any]]) ?? [] {
            
            let groupName = group["Group"] as! String
            let tidemark = group["Tidemark"] as! String
            
            // now pull out the changes for this group
            for change in (group["Changes"] as? [[String:Any]]) ?? [] {
                
                let path = (change["Path"] as? String ?? "//").components(separatedBy: "/")
                let value = change["Value"] as? String ?? ""
                // let modified = change["Modified"] as? String ?? ""
                let operation = change["Operation"] as? SharkSyncOperation ?? .Undefined
                let record_id = path[0]
                let class_name = path[1]
                let property = path[2]
                
                // process this change
                if operation == .Delete {
                    
                    /* just delete the record and add an entry into the destroyed table to prevent late arrivals from breaking things */
                    let objClass: AnyClass? = NSClassFromString(class_name)
                    if objClass != nil {
                        let deadObject: SRKSyncObject? = objClass!.object(withPrimaryKeyValue: NSString(string: record_id)) as? SRKSyncObject
                        if deadObject != nil {
                            deadObject?.__removeRawNoSync()
                        }
                        let defObj = SRKDefunctObject()
                        defObj.defunctId = record_id
                        defObj.commit()
                        
                    }
                    
                } else {
                    
                    // deal with an insert/update
                    
                    let objClass: AnyClass? = NSClassFromString(class_name)
                    if objClass != nil {
                        
                        // existing object, uopdate the value
                        var decryptedValue = SharkSync.decryptValue(value)
                        
                        let targetObject: SRKSyncObject? = objClass!.object(withPrimaryKeyValue: NSString(string: record_id)) as? SRKSyncObject
                        if targetObject != nil {
                            
                            // check to see if this property is actually in the class, if not, store it for a future schema
                            for fieldName: String in targetObject!.fieldNames() as! [String] {
                                if (fieldName == property) {
                                    targetObject?.setField(property, value: decryptedValue as! NSObject)
                                    if targetObject?.__commitRaw(withObjectChainNoSync: nil) != nil {
                                        decryptedValue = nil
                                    }
                                }
                            }
                            
                            if decryptedValue != nil {
                                
                                // cache this object for a future instance of the schema, when this field exists
                                let deferredChange = SRKDeferredChange()
                                deferredChange.key = record_id
                                deferredChange.className = class_name
                                deferredChange.value = value
                                deferredChange.property = property
                                deferredChange.commit()
                                
                            }
                            
                        }
                        else {
                            if SRKDefunctObject.query().where(withFormat: "defunctId = %@", withParameters: [record_id]).count() > 0 {
                                // defunct object, do nothing
                            }
                            else {
                                // not previously defunct, but new key found, so create an object and set the value
                                let cls = NSClassFromString(class_name) as? SRKSyncObject.Type
                                let targetObject = cls?.init()
                                if targetObject != nil {
                                    
                                    targetObject!.id = record_id
                                    
                                    // check to see if this property is actually in the class, if not, store it for a future schema
                                    for fieldName: String in targetObject!.fieldNames() as! [String] {
                                        if (fieldName == property) {
                                            targetObject!.setField(property, value: decryptedValue as! NSObject)
                                            if targetObject!.__commitRaw(withObjectChainNoSync: nil) {
                                                decryptedValue = nil
                                            }
                                        }
                                    }
                                    if decryptedValue != nil {
                                        // cache this object for a future instance of the schema, when this field exists
                                        let deferredChange = SRKDeferredChange()
                                        deferredChange.key = record_id
                                        deferredChange.className = class_name
                                        deferredChange.value = value
                                        deferredChange.property = property
                                        deferredChange.commit()
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
            }
            
            // now update the group tidemark so as to not receive this data again
            let grp = SRKSyncGroup.groupWithEncodedName(groupName)
            if grp != nil {
                grp!.tidemark_uuid = tidemark
                grp!.last_polled = NSNumber(value: Date().timeIntervalSince1970)
                grp!.commit()
            }
            
        }
    }
}
