//
//  AULog.swift
//  Augustus
//
//  Created by Ryan Globus on 8/8/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation

typealias AULogger = (AnyObject?) -> ()

class AULog {
    enum Level {
        case Debug, Info, Warn, Error
        
    }
    
    static let instance = AULog(minLevel: .Debug)
    let minLevel: Level
    let debug: AULogger?
    let info: AULogger?
    let warn: AULogger?
    let error: AULogger?
    
    init(minLevel: Level) {
        self.minLevel = minLevel
        
        func loggerForLevel(levelString: NSString) -> AULogger {
            return {(msg_: AnyObject?) -> () in
                let now = NSDate()
                print("[\(now)] \(levelString) - ")
                if let msg: AnyObject = msg_ {
                    println(msg)
                } else {
                    println()
                }
            }
        }
        
        self.error = loggerForLevel("ERROR")
        if (self.minLevel == .Error) {
            self.warn = nil
            self.info = nil
            self.debug = nil
            return
        }
        self.warn = loggerForLevel("WARN")
        if (self.minLevel == .Warn) {
            self.info = nil
            self.debug = nil
            return
        }
        self.info = loggerForLevel("INFO")
        if (self.minLevel == .Info) {
            self.debug = nil
            return
        }
        self.debug = loggerForLevel("DEBUG")
    }
    
}
