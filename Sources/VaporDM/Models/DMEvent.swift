//
//  DMEvent.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import Foundation
import Vapor
import JSON

/// Event status
///
/// - success: if message was sent
/// - failure: if message wasn't sent
public enum DMStatus {
    case success
    case failure
}

/// VaporDM's event object. Represents status of sent message to the group of receivers
public struct DMEvent<T: DMParticipant> {
    public var status: DMStatus
    public var message: JSON
    public var users: [T]
    
    /// Creates event object
    ///
    /// - Parameters:
    ///   - users: Group of receivers
    ///   - message: message JSON object
    ///   - status: message status
    public init(_ users: [T], message: JSON, status: DMStatus = .success) {
        self.message = message
        self.status = status
        self.users = users
    }
}
