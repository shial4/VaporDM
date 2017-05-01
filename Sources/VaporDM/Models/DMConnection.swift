//
//  DMConnection.swift
//  VaporDM
//
//  Created by Shial on 01/05/2017.
//
//

import Foundation
import Vapor

struct DMConnection {
    var id: String
    var userId: String
    var socket: WebSocket
    
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


