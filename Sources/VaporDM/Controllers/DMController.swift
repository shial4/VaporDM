//
//  DMController.swift
//  VaporDM
//
//  Created by Shial on 19/04/2017.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

public final class DMController {
    
    open var group: String = "chat"
    fileprivate weak var drop: Droplet?
    fileprivate var connections: [String: WebSocket] = [:]
    
    public init<T:DMUser>(drop: Droplet, model: T.Type) {
        self.drop = drop
        drop.preparations += [Pivot<T, DMRoom>.self]
        let chat = drop.grouped(group)
        chat.socket("service", T.self, handler: chatService)
        chat.get("history", String.self, handler: history)
    }
    
    public func history(request: Request, room: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(room) else {
            throw Abort.notFound
        }
        guard let from = request.data["from"]?.double else {
                return try room.messages().makeJSON()
        }
        guard let to = request.data["to"]?.double else {
            return try room.messages(from: from).makeJSON()
        }
        return try room.messages(from: from, to: to).makeJSON()
    }
    
    public func chatService<T:DMUser>(request: Request, ws: WebSocket, user: T) {
        ws.onText = { ws, text in
            guard let id = user.id?.string else {
                print("Unable to get user unigeId")
                return
            }
            self.connections[id] = ws
            do {
                let message = try DirectMessage(sender: user, message: text)
                let response: (redirect: JSON, receivers: [T]) = try message.parseMessage()
                for (id, socket) in self.connections where response.receivers.contains(where: { reveiver -> Bool in
                    guard id == reveiver.id?.string else {
                        return false
                    }
                    return true
                }) {
                    try socket.send(response.redirect)
                }
            } catch {
                print(error)
            }
        }
        
        ws.onClose = { ws, _, _, _ in
            guard let id = user.id?.string else {
                print("Unable to get user unigeId")
                return
            }
            self.connections.removeValue(forKey: id)
        }
    }
}
