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

public enum DMLogType {
    case info
    case warning
    case error
}

public struct DMLog {
    public var type: DMLogType
    public var message: String
    public var fileName: String
    public var functionName: String
    public var line: Int
    
    public init(message: String, type: DMLogType = .info, file: String = #file, line: Int = #line, function: String = #function) {
        self.message = message
        self.type = type
        self.fileName = file
        self.line = line
        self.functionName = function
    }
    
    public func dispatch<T:DMUser>(_ sender: T) {
        DispatchQueue.global().async {
            T.directMessageLog(self)
        }
    }
}
