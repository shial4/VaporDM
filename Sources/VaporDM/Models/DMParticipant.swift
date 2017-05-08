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

/// Aliast for Model and DMParticipant protocol corresponding reuirement
public typealias DMUser = Model & DMParticipant

/// User status
public enum DMUserStatus {
    /// if user is offline
    case offline
    ///  is user is online
    case online
    ///  is user is away from keyboard
    case away
}

/// Participant protocol required for VaporDM initialization
public protocol DMParticipant {
    /// Optional direct message protocol method, forwarded to you before it will be dispatch to receivers. In good practise, If you have your own users setting which may cancel message before send, this is the place to cancel it by returning nil object instead of message. By default message should be returned there
    ///```
    ///public static func directMessage(_ sender: User, message: JSON, type: DMType) -> JSON? {
    ///   return message
    ///}
    ///```
    ///
    /// - Parameters:
    ///   - sender: Your object correcpond to this protocol which is associated as a sender for this message
    ///   - message: message JSON object
    ///   - type: type of message
    /// - Returns: message JSON
    static func directMessage(_ sender: Self, message: JSON, type: DMType) -> JSON?
    /// Log protocol message. Called everytime time is trigger inside VaporDM. Thans to this method you are able to handle log and have a wider look on the stuff happening inside.
    ///
    /// - Parameter log: Log object
    static func directMessageLog(_ log: DMLog)
    static func directMessageEvent(_ event: DMEvent<Self>)
}

extension DMParticipant {
    /// Optional direct message protocol method implementation, If override by you then forwarded before it will be dispatch to receivers. In good practise, If you have your own users setting which may cancel message before send, this is the place to cancel it by returning nil object instead of message. By default message should be returned there
    ///```
    ///public static func directMessage(_ sender: User, message: JSON, type: DMType) -> JSON? {
    ///   return message
    ///}
    ///```
    ///
    /// - Parameters:
    ///   - sender: Your object correcpond to this protocol which is associated as a sender for this message
    ///   - message: message JSON object
    ///   - type: type of message
    /// - Returns: message JSON
    fileprivate static func directMessage(_ sender: Self, message: JSON, type: DMType) -> JSON? {
        return message
    }
}

public extension DMParticipant {    
    /// DMEvent protocol method, to dispatch operation on bacground queue
    ///
    /// - Parameter event: event to be delivered
    static func directMessage(event: DMEvent<Self>) {
        DispatchQueue.global().async {
            Self.directMessageEvent(event)
        }
    }
    /// DMLog protocol method, to dispatch operation on bacground queue
    ///
    /// - Parameter log: log to be delivered
    static func directMessage(log: DMLog) {
        DispatchQueue.global().async {
            Self.directMessageLog(log)
        }
    }
}

public extension DMParticipant where Self: Model {    
    /// Get rooms for current Participant
    ///
    /// - Returns: Fluent Siblings between this user and chat rooms
    /// - Throws: Error if something goes wrong
    public func rooms() throws -> Siblings<DMRoom> {
        return try siblings()
    }
    /// Get participant messages
    ///
    /// - Returns: messages owned by this participant
    /// - Throws: Error if something goes wrong
    public func messages() throws -> Children<DMDirective> {
        return children(DMDirective.Constants.owner)
    }
}
