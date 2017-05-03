//
//  DMLog.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import Foundation
import Vapor
import Dispatch

/// VaporDM's Log type
public enum DMLogType {
    /// type represents information
    case info
    /// type represents warning
    case warning
    /// type indicating error
    case error
}

/// Log object representing log type message and location where this log did appear.
public struct DMLog {
    /// Log type
    public var type: DMLogType
    /// Log message
    public var message: String
    /// File in which Log was created
    public var fileName: String
    /// Function in which log was created
    public var functionName: String
    /// Line of file in which log was created
    public var line: Int
    
    /// Create Log object
    ///
    /// - Parameters:
    ///   - message: Log message
    ///   - type: Log type
    ///   - file: File in which Log was created
    ///   - line: Line of file in which log was created
    ///   - function: Function in which log was created
    public init(message: String, type: DMLogType = .info, file: String = #file, line: Int = #line, function: String = #function) {
        self.message = message
        self.type = type
        self.fileName = file
        self.line = line
        self.functionName = function
    }
}
