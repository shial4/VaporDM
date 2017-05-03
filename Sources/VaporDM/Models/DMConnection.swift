//
//  DMConnection.swift
//  VaporDM
//
//  Created by Shial on 01/05/2017.
//
//

import Foundation
import Vapor

/// VaporsDM connection, holds User and WebSocket with custom id to allow one user for multiple connections.
struct DMConnection {
    /// Connection id
    var id: String
    /// User id
    var userId: String
    /// Websocket under user is connected
    var socket: WebSocket
    /// Create DMConnection object
    ///
    /// - Parameters:
    ///   - id: connection id, should be unique
    ///   - user: user id
    ///   - socket: WebSocket
    init(id: String, user: String, socket: WebSocket) {
        self.id = id
        self.userId = user
        self.socket = socket
    }
}

extension DMConnection: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
    
    static func ==(lhs: DMConnection, rhs: DMConnection) -> Bool {
        return lhs.userId == rhs.userId && lhs.socket === rhs.socket
    }
}


