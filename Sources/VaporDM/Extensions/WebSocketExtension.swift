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
    func send(_ json: JSON) throws {
        try send(json.makeBytes().string)
    }
}
