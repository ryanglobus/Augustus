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
        case debug = 1, info, warn, error
        
        var description: String {
            switch self {
                case .debug: return "DEBUG"
                case .info: return "INFO"
                case .warn: return "WARN"
                case .error: return "ERROR"
            }
        }
    }
    
    static let instance = AULog(minLevel: .debug)
    let minLevel: Level
    
    init(minLevel: Level) {
        self.minLevel = minLevel
    }

    func log(_ message_: Any?, level: Level, file: String = #file, line: Int = #line) {
        var file = file
        guard level.rawValue >= self.minLevel.rawValue else {
            return
        }

        file = (file as NSString).lastPathComponent
        if let message = message_ {
            NSLog("\(level) (\(file):\(line)) - \(message)")
        } else {
            NSLog("\(level) (\(file):\(line)) - ")
        }
    }

    func debug(_ message_: Any?, file: String = #file, line: Int = #line) {
        log(message_, level: .debug, file: file, line: line)
    }

    func info(_ message_: Any?, file: String = #file, line: Int = #line) {
        log(message_, level: .info, file: file, line: line)
        
    }

    func warn(_ message_: Any?, file: String = #file, line: Int = #line) {
        log(message_, level: .warn, file: file, line: line)
    }

    func error(_ message_: Any?, file: String = #file, line: Int = #line) {
        log(message_, level: .error, file: file, line: line)
    }

}
