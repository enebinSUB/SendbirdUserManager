//
//  File.swift
//  
//
//  Created by YoungBin Lee on 1/2/24.
//

import os.log
import Foundation

/// A simple logger that wraps the `os_log` functionality for easy logging throughout the app.
/// The logger has been simplified to use only two log levels: error and info
struct Logger {
    static let shared = Logger(subsystem: "SendbirdUserManager", category: "System")
    
    private let subsystem: String
    private let category: String

    init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    private func log(_ message: String, type: OSLogType, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[SendbirdUserManager] \(fileName):\(line) \(function) - \(message)"
        let log = OSLog(subsystem: subsystem, category: category)
        
        os_log("%{public}@", log: log, type: type, logMessage)
    }
    
    private func simpleLog(_ message: String, type: OSLogType) {
        let log = OSLog(subsystem: subsystem, category: category)
        
        os_log("%{public}@", log: log, type: type, "[SendbirdUserManager] " + message)
    }

    func info(_ message: String) {
        simpleLog(message, type: .info)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, type: .error, file: file, function: function, line: line)
    }
}
