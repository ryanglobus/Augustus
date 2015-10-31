//
//  AULog.swift
//  Augustus
//
//  Created by Ryan Globus on 8/8/15.
//  Copyright (c) 2015 Ryan Globus. All rights reserved.
//

import Foundation

class AULog {
    enum Level: Int, CustomStringConvertible {
        case Debug = 1, Info, Warn, Error
        
        var description: String {
            switch self {
                case .Debug: return "DEBUG"
                case .Info: return "INFO"
                case .Warn: return "WARN"
                case .Error: return "ERROR"
            }
        }
    }
    
    static let instance = AULog(minLevel: .Debug)
    let minLevel: Level
    
    init(minLevel: Level) {
        self.minLevel = minLevel
    }

    func log(message_: Any?, level: Level, var file: String = __FILE__, line: Int = __LINE__) {
        guard level.rawValue >= self.minLevel.rawValue else {
            return
        }

        if let lastSeparator = file.rangeOfString("/", options: .BackwardsSearch)?.startIndex.successor() {
            file = file.substringFromIndex(lastSeparator)
        }
        if let message = message_ {
            NSLog("\(level) (\(file):\(line)) - \(message)")
        } else {
            NSLog("\(level) (\(file):\(line)) - ")
        }
    }

    func debug(message_: Any?, file: String = __FILE__, line: Int = __LINE__) {
        log(message_, level: .Debug, file: file, line: line)
    }

    func info(message_: Any?, file: String = __FILE__, line: Int = __LINE__) {
        log(message_, level: .Info, file: file, line: line)
        
    }

    func warn(message_: Any?, file: String = __FILE__, line: Int = __LINE__) {
        log(message_, level: .Warn, file: file, line: line)
    }

    func error(message_: Any?, file: String = __FILE__, line: Int = __LINE__) {
        log(message_, level: .Error, file: file, line: line)
    }

}
