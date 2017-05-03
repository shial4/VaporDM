//
//  WebSocketExtension.swift
//  VaporDM
//
//  Created by Shial on 21/04/2017.
//
//

import Foundation
import Vapor

extension WebSocket {
    /// Send JSON object over WebSocket
    ///
    /// - Parameter json: message object
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func send(_ json: JSON) throws {
        try send(json.makeBytes().string)
    }
}
