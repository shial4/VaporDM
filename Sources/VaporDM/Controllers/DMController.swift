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
    /// Group under which endpoints are grouped
    open var group: String = "chat"
    /// An Droplet instance under endpoint are handled
    fileprivate weak var drop: Droplet?
    /// VaporDM configuraton object
    fileprivate var configuration: DMConfiguration
    /// VaporDM connection set
    fileprivate var connections: Set<DMConnection> = []
    /// Function which expose Models instance for Vapor Fluent to exten your database.
    ///
    /// - Returns: Preparation reuired for VaporDM to work on database
    fileprivate func models() -> [Preparation.Type] {
        return [Pivot<T, DMRoom>.self,
                DMRoom.self,
                DMDirective.self,
        ]
    }
    
    /// DMController object which do provide endpoint to work with VaporDM
    ///
    /// - Parameters:
    ///   - droplet: Droplet object required to correctly set up VaporDM
    ///   - configuration: DMConfiguration object required to configure VaporDM. Default value is DMDefaultConfiguration() object
    public init(drop: Droplet, configuration: DMConfiguration) {
        self.drop = drop
        self.configuration = configuration
        drop.preparations += models()
        let chat = drop.grouped(group)
        chat.socket("service", T.self, handler: chatService)
        chat.post("room", handler: createRoom)
        chat.post("room", String.self, handler: addUsersToRoom)
        chat.get("room", String.self, handler: getRoom)
        chat.get("room", String.self, "participant", handler: getRoomParticipants)
        chat.get("participant", T.self, "rooms", handler: getParticipantRooms)
        chat.get("history", String.self, handler: history)
    }
    
    /// Create chat room.
    ///```
    /// POST: /chat/room
    /// "Content-Type" = "application/json"
    ///```
    /// In Body DMRoom object with minimum uniqueid and name parameters.
    ///```
    /// {
    ///     "uniqueid":"",
    ///     "name":"RoomName"
    /// }
    ///```
    /// - Parameters:
    ///   - request: request object
    ///   - uniqueId: Chat room UUID
    /// - Returns: CHat room
    /// - Throws: If room is not found or query do fail
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
    
    /// Get chat room.
    ///
    ///```
    /// GET: /chat/room/${room_uuid}
    /// "Content-Type" = "application/json"
    ///```
    ///
    /// - Parameters:
    ///   - request: request object
    ///   - uniqueId: Chat room UUID
    /// - Returns: Chat room
    /// - Throws: If room is not found or query do fail
    public func getRoom(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(uniqueId.lowercased()) else {
            throw Abort.notFound
        }
        return try room.makeJSON()
    }
    
    /// Add users to room.
    ///
    ///```
    /// POST: /chat/room/${room_uuid}
    /// "Content-Type" = "application/json"
    ///```
    /// In Body Your Fluent Model or array of models which is associated with VaporDM.
    ///```
    /// {
    ///     [
    ///         ${<User: Model, DMParticipant>},
    ///         ${<User: Model, DMParticipant>}
    ///     ]
    /// }
    ///```
    /// Or
    ///```
    /// {
    ///     ${<User: Model, DMParticipant>}
    /// }
    ///```
    /// - Parameters:
    ///   - request: request object
    ///   - uniqueId: Chat room UUID
    /// - Returns: CHat room
    /// - Throws: If room is not found or query do fail
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
    
    /// Get DMRoom participants
    ///
    ///```
    /// GET: /chat/room/${room_uuid}/participant
    /// "Content-Type" = "application/json"
    ///```
    ///
    /// - Parameters:
    ///   - request: request object
    ///   - uniqueId: Chat room UUID
    /// - Returns: Array of You Fluent object, which corresponds to DMParticipant and FLuent's Model Protocols
    /// - Throws: If room is not found or query do fail
    public func getRoomParticipants(request: Request, uniqueId: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(uniqueId.lowercased()) else {
            throw Abort.notFound
        }
        let users: [T] = try room.participants()
        return try users.makeJSON()
    }
    
    /// Get DMParticipant rooms. This request passes in url Your Fluent model `id` which is associated with VaporDM's
    ///
    ///```
    /// GET: /chat/participant/${user_id}/rooms
    /// "Content-Type" = "application/json"
    ///```
    /// - Parameters:
    ///   - request: request object
    ///   - user: Your Fluent Associated model with VaporDM
    /// - Returns: Array of DMRoom object which your User participate
    /// - Throws: If query goes wrong
    public func getParticipantRooms(request: Request, user: T) throws -> ResponseRepresentable {
        let rooms: [DMRoom] = try user.rooms().all()
        return try rooms.makeJSON()
    }
    
    /// Get chat room history. You can pass in request data `from` and `to` values which constrain query
    ///```
    /// GET: /chat/history/${room_uuid}
    /// "Content-Type" = "application/json"
    ///```
    ///
    /// - Parameters:
    ///   - request: request object
    ///   - room: chat room UUID for which history will be retirned
    /// - Returns: Array of DMDirective objects
    /// - Throws: If room is not found or query will throw
    public func history(request: Request, room: String) throws -> ResponseRepresentable {
        guard let room = try DMRoom.find(room) else {
            throw Abort.notFound
        }
        return try room.messages(from: request.data["from"]?.double, to: request.data["to"]?.double).makeJSON()
    }
    
    /// Called when a WebSocket client connects to the server
    ///```
    /// ws: /chat/service/${user_id}
    ///```
    ///
    /// - Parameters:
    ///   - request: WebSocket connection request
    ///   - ws: WebSocket
    ///   - user: User which did connect
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
        let connectionIdentifier = UUID().uuidString
        T.directMessage(log: DMLog(message: "User: \(user.id ?? "") did connect", type: .info))

        do {
            let message = try DMFlowController(sender: user, message: JSON([DMKeys.type:String(DMType.connected.rawValue).makeNode()]))
            self.sendMessage(message)
        } catch {
            T.directMessage(log: DMLog(message: "\(error)", type: .error))
        }
        let connection = DMConnection(id: connectionIdentifier, user: id, socket: ws)
        applyConfiguration(for: connection)
        self.connections.insert(connection)
        
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
            self.connections.remove(DMConnection(id: connectionIdentifier, user: id, socket: ws))
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
    /// Send message over the WebSocket thanks to DMFlowController `parseMessage` method result.
    ///
    /// - Parameter message: DMFlowController instance
    func sendMessage<T:DMUser>(_ message: DMFlowController<T>) {
        do {
            let response: (redirect: JSON?, receivers: [T]) = try message.parseMessage()
            guard let redirect = response.redirect else { return }
            var offline = response.receivers
            var online: [T] = []
            for connection in self.connections where response.receivers.contains(where: { reveiver -> Bool in
                guard connection.userId == reveiver.id?.string else {
                    return false
                }
                return true
            }) {
                try connection.socket.send(redirect)
                if let removed = offline.remove(connection.userId) {
                    online.append(removed)
                }
            }
            T.directMessage(event: DMEvent(online ,message: redirect))
            T.directMessage(event: DMEvent(offline ,message: redirect, status: .failure))
        } catch {
            T.directMessage(log: DMLog(message: "\(error)", type: .error))
        }
    }
    /// Apply DMConfiguration instance for current connection passed in argument.
    ///
    /// - Parameter connection: Configuration which specify among others ping time interval.
    func applyConfiguration(for connection: DMConnection) {
        guard let interval = configuration.pingIterval else {
            T.directMessage(log: DMLog(message: "Skipping ping sequence. DMConfiguration do not specify ping interval.", type: .info))
            return
        }
        connection.ping(every: interval)
    }
}

extension Request {
    /// Parse Requesto JSON to chat room object
    ///
    /// - Returns: chat room object
    /// - Throws: Error if something goes wrong
    func room() throws -> DMRoom {
        guard let json = json else { throw Abort.badRequest }
        return try DMRoom(node: json)
    }
    /// Parse Request JSON to your Fluent model
    ///
    /// - Returns: Array of you Fluent models
    /// - Throws: Error if something goes wrong
    func users<T:DMUser>() throws -> [T] {
        guard let json = json else { throw Abort.badRequest }
        guard let array = json.pathIndexableArray else {
            return [try T(node: json)]
        }
        return try array.map() { try T(node: $0)}
    }
}
