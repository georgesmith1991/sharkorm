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

class SyncNetwork {
    
    static let sharedInstance = SyncNetwork()
    private init() {}
    
    var authToken: String = ""
    var endpoints: [String] = []
    
    // data to be sent with each request to the service
    var device_id: String?
    var app_id: String?
    var api_key: String?
    var initialised: Bool = false
    
    // the outbound packet queue as an array of mutable dictionaries
    private var queue: [RequestCarrier] = []
    
    // status change blocks
    private var connected: Bool = false
    private var connectionEstablishedClosure: (()->())? = nil
    private var connectionDisconnectedClosure: ((_ error: String?)->())? = nil

    private var lock: Mutex = Mutex()
    
    // add an item to the queue, with the matching closure to be executed when complete
    func queueItem(_ request: RequestCarrier) {
        lock.mutex {
            queue.append(request)
        }
    }
    
    // removes all queued items from the queue
    func resetQueue() {
        lock.mutex {
            queue.removeAll()
        }
    }
    
    // remove a specific request from the queue, e.g. change group visibility
    func removeRequest(identifier: String) {
        
        lock.mutex {
            
            var i = 0
            var idx: Int? = nil
            
            for r in self.queue {
                if r.requestIdentifier == identifier {
                    idx = i
                    break
                }
                i += 1
            }
            
            if idx != nil {
                queue.remove(at: idx!)
            }
            
        }
        
    }
    
    // set the block which gets executed when service is online & available
    // use this to setup the initial request framework
    
    func setConnectedClosure(_ closure: (()->())?) {
        connectionEstablishedClosure = closure
    }
    
    // set the block which gets executed when service is unavailable.
    // Such as out of credit, auth errors etc..., permanent errors, no connection
    func setDisconnectedClosure(_ closure: ((_ error: String?)->())?) {
        connectionDisconnectedClosure = closure
    }
    
    func runQueue() {
        
        while(true) {
            
            if initialised {
            
                // this function runs in perpetuity, sending all requests in the queue to the endpoint
                var r: RequestCarrier? = nil
                
                lock.mutex {
                    // pull the first object from the queue
                    if queue.count > 0 {
                        r = queue[0]
                        queue.remove(at: 0)
                    }
                }
                
                if r != nil {
                    
                    // we have a request, lets pack this off to the service
                    let s = SyncComms()
                    let response = s.request(payload: (r?.payload)!)
                    if response != nil {
                        r?.closure!(SyncRequestStatus.Success, response!)
                    } else {
                        r?.closure!(SyncRequestStatus.Failed, nil)
                    }
                    
                }
                
            }
            
            Thread.sleep(forTimeInterval: 1)
            
        }
        
    }
}
