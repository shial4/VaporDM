//
//  DMParticipant.swift
//  VaporDM
//
//  Created by Shial on 20/04/2017.
//
//

import Foundation
import Dispatch
import Vapor
import Fluent

public typealias DMUser = Model & DMParticipant

public enum DMUserStatus {
    case offline
    case online
    case away
}

public protocol DMParticipant {
    static func directMessage(_ sender: Self, message: JSON, type: DMType) -> JSON?
    static func directMessageLog(_ log: DMLog)
    static func directMessageEvent(_ event: DMEvent<Self>)
}

public extension DMParticipant {
    public static func directMessage<T: DMUser>(_ sender: T, message: JSON, type: DMType) -> JSON? {
        return Self.directMessage(sender, message: message, type: type)
    }
    
    public static func directMessage(event: DMEvent<Self>) {
        DispatchQueue.global().async {
            Self.directMessageEvent(event)
        }
    }
    
    public static func directMessage(log: DMLog) {
        DispatchQueue.global().async {
            Self.directMessageLog(log)
        }
    }
}

public extension DMParticipant where Self: Model {    
    public func rooms() throws -> Siblings<DMRoom> {
        return try siblings()
    }
    
    public func messages() throws -> Children<DMDirective> {
        return children(DMDirective.Constants.owner)
    }
}
