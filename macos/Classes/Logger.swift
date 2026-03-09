import Foundation
import os.log

/// A logger utility that only logs in debug mode
class Logger {
    private static let subsystem = "com.media_browser"
    private static let category = "MediaExtraction"
    
    private static let logger = OSLog(subsystem: subsystem, category: category)
    
    /// Log a message only in debug mode
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level (default: .debug)
    static func log(_ message: String, level: OSLogType = .debug) {
        #if DEBUG
        // Print to console for Flutter debugging
        print(message)
        // Also log to os_log for system logging
        os_log("%{public}@", log: logger, type: level, message)
        #endif
    }
    
    /// Log an info message
    static func info(_ message: String) {
        log(message, level: .info)
    }
    
    /// Log a debug message
    static func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    /// Log an error message
    static func error(_ message: String) {
        log(message, level: .error)
    }
    
    /// Log a warning message
    static func warning(_ message: String) {
        log(message, level: .default)
    }
}
