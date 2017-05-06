//
//  DMConnection.swift
//  VaporDM
//
//  Created by Shial on 01/05/2017.
//
//

import Foundation
import Vapor
import Dispatch

/// VaporsDM connection, holds User and WebSocket with custom id to allow one user for multiple connections.
class DMConnection {
    /// Connection id
    var id: String
    /// User id
    var userId: String
    /// Websocket under user is connected
    var socket: WebSocket!
    /// Timer to hold WebSOcket connection
    var timer: DispatchSourceTimer?
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
    /// Create DMConnection object without WebSocket instance. For test purpose
    ///
    /// - Parameters:
    ///   - id: connection id, should be unique
    ///   - user: user id
    init(id: String, user: String) {
        self.id = id
        self.userId = user
    }
    /// Ping the socket to keep it open
    ///
    /// - Parameter seconds: Time interval (in seconds) between pings
    func ping(every seconds: Int, callback: (() -> ())? = nil ) {
        let queue = DispatchQueue(label: "com.chat.app.ping.timer.\(id)", attributes: .concurrent)
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(seconds), leeway: .seconds(1))
        timer?.setEventHandler { [weak self] in
            callback?()
            if self?.socket?.state == .open {
                try? self?.socket?.ping()
            }
        }
        timer?.resume()
    }
    
    deinit {
        timer?.cancel()
        timer = nil
    }
}

extension DMConnection: Hashable {
    var hashValue: Int {
        return id.hashValue
    }
    
    static func ==(lhs: DMConnection, rhs: DMConnection) -> Bool {
        return lhs.id == rhs.id && lhs.userId == rhs.userId && lhs.socket === rhs.socket
    }
}


