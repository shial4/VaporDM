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

public final class DMController<T:DMUser> {
    
    open var group: String = "chat"
    fileprivate weak var drop: Droplet?
    fileprivate var connections: [String: WebSocket] = [:]
    fileprivate func models() -> [Preparation.Type] {
        return [Pivot<T, DMRoom>.self,
                DMRoom.self,
                DMDirective.self,
        ]
    }
    
    public init(drop: Droplet) {
        self.drop = drop
        drop.preparations += models()
        let chat = drop.grouped(group)
        chat.socket("service", T.self, handler: chatService)
        chat.post("room", handler: createRoom)
        chat.post("room", String.self, handler: addUsersToRoom)
        chat.get("room", String.self, handler: getRoom)
        chat.get("room", String.self, "participant", handler: getRoomParticipant)
        chat.get("history", String.self, handler: history)
    }
    
    public func createRoom(request: Request) throws -> ResponseRepresentable {
        var room = try request.room()
        try room.save()
        if let users: [String] = try request.json?.extract("participants") {
            for userId in users {
                do {
                    if let user = try T.find(userId) {
                        _ = try Pivot<T, DMRoom>.getOrCreate(user, room)
                    }
                } catch {
                    T.directMessage(log: DMLog(message: "Unable to find user with id: \(userId)\nError message: \(error)", type: .warning))
                }
            }
        }
        return try room.makeJSON()
    }
    
    public func getRoom(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(uniqueId.lowercased()) else {
            throw Abort.notFound
        }
        return try room.makeJSON()
    }
    
    public func addUsersToRoom(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard var room = try DMRoom.find(uniqueId.lowercased()) else {
            throw Abort.notFound
        }
        room.updated = Date()
        try room.save()
        for user: T in try request.users() {
            _ = try Pivot<T, DMRoom>.getOrCreate(user, room)
        }
        return try room.makeJSON()
    }
    
    public func getRoomParticipant(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(uniqueId.lowercased()) else {
            throw Abort.notFound
        }
        let users: [T] = try room.participants()
        return try users.makeJSON()
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
        guard let id = user.id?.string else {
            T.directMessage(log: DMLog(message: "Unable to get user unigeId", type: .error))
            do {
                try ws.close()
            } catch {
                T.directMessage(log: DMLog(message: "\(error)", type: .error))
            }
            return
        }
        do {
            let message = try DMFlowController(sender: user, message: JSON([DMKeys.type:String(DMType.connected.rawValue).makeNode()]))
            self.sendMessage(message)
        } catch {
            T.directMessage(log: DMLog(message: "\(error)", type: .error))
        }
        self.connections[id] = ws
        
        ws.onText = { ws, text in
            do {
                let message = try DMFlowController(sender: user, message: try JSON(bytes: Array(text.utf8)))
                self.sendMessage(message)
            } catch {
                T.directMessage(log: DMLog(message: "\(error)", type: .error))
            }
        }
        
        ws.onClose = { ws, _, _, _ in
            guard let id = user.id?.string else {
                T.directMessage(log: DMLog(message: "Unable to get user unigeId", type: .error))
                return
            }
            self.connections.removeValue(forKey: id)
            do {
                let message = try DMFlowController(sender: user, message: JSON([DMKeys.type:String(DMType.disconnected.rawValue).makeNode()]))
                self.sendMessage(message)
            } catch {
                T.directMessage(log: DMLog(message: "\(error)", type: .error))
            }
        }
    }
}

extension DMController {
    fileprivate func sendMessage<T:DMUser>(_ message: DMFlowController<T>) {
        do {
            let response: (redirect: JSON?, receivers: [T]) = try message.parseMessage()
            guard let redirect = response.redirect else { return }
            var offline = response.receivers
            var online: [T] = []
            for (id, socket) in self.connections where response.receivers.contains(where: { reveiver -> Bool in
                guard id == reveiver.id?.string else {
                    return false
                }
                return true
            }) {
                try socket.send(redirect)
                if let removed = offline.remove(id) {
                    online.append(removed)
                }
            }
            T.directMessage(event: DMEvent(online ,message: redirect))
            T.directMessage(event: DMEvent(offline ,message: redirect, status: .failure))
        } catch {
            T.directMessage(log: DMLog(message: "\(error)", type: .error))
        }
    }
}

extension Request {
    func room() throws -> DMRoom {
        guard let json = json else { throw Abort.badRequest }
        return try DMRoom(node: json)
    }
    func users<T:DMUser>() throws -> [T] {
        guard let json = json else { throw Abort.badRequest }
        guard let array = json.pathIndexableArray else {
            return [try T(node: json)]
        }
        return try array.map() { try T(node: $0)}
    }
}
