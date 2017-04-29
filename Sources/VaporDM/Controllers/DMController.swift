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
        return try room.makeJSON()
    }
    
    public func getRoom(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(uniqueId) else {
            throw Abort.notFound
        }
        return try room.makeJSON()
    }
    
    public func addUsersToRoom(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard var room = try DMRoom.find(uniqueId) else {
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
        guard let room = try DMRoom.find(uniqueId) else {
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
