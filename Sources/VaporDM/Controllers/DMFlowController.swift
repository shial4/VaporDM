//
//  DMFlowController.swift
//  VaporDM
//
//  Created by Shial on 18/04/2017.
//
//

import Foundation
import Vapor
import Fluent


/// Error types and description
public enum DMFlowControllerError: CustomStringConvertible, Error {
    case missingSenderId
    case jsonWrongContent
    case unableToReadRoomParameter
    case unableToReadMessageTypeParameter
    case unknowMessageType
    case unableToReadBodyParameter
    case unableToGetOrCreatePivot
    
    public var description: String {
        switch self {
        case .jsonWrongContent:
            return "JSON have wrong context"
        case .unableToReadRoomParameter:
            return "unable to read room parameter"
        case .unableToReadMessageTypeParameter:
            return "unable to read message type"
        case .unknowMessageType:
            return "unknown message type"
        case .unableToReadBodyParameter:
            return "unable to ready body parameter"
        case .missingSenderId:
            return "missing sender's id"
        case .unableToGetOrCreatePivot:
            return "unable to get or create pivot"
        }
    }
}


/// Representation of JSON direct message keys
public struct DMKeys {
    static let room = "room"
    static let type = "type"
    static let body = "body"
    static let sender = "sender"
}


/// Direct message type
public enum DMType: Character {
    /// User did connect to WebSocket
    case connected = "C"
    /// User did disconnect from WebSocket
    case disconnected = "D"
    /// Text message, indicating there should be body parameter in JSON
    case messageText = "M"
    /// User start typing even message
    case beginTyping = "B"
    /// User end typing event message
    case endTyping = "E"
    /// User did read message
    case readMessage = "R"
}


/// Message flow controller, responsible for parsing data in middle of receive messag from user before it's dispatch to receivers.
struct DMFlowController<T: DMUser> {
    /// Chat room object, some message types require chat room to deliver message.
    var room: DMRoom?
    /// Fluent model associated as a sender for this message.
    var sender: T
    /// message JSON object
    var json: JSON
    
    
    /// Create DMFlowController for given sender Fluent model object with JSON message
    ///
    /// - Parameters:
    ///   - sender: Fluent's Model object associated with message as a sender
    ///   - json: JSON message object
    /// - Throws: If anything bad occurred during initialization, error message will be thrown
    init(sender: T, message json: JSON) throws {
        self.json = json
        self.sender = sender
        if let room = json.object?[DMKeys.room]?.string  {
            self.room = try createRoomIfNedded(id: room)
        }
    }
    
    /// If room does not exist is being created and then returned otherwise room is returned for given UUID
    ///
    /// - Parameter id: Chat room UUID
    /// - Returns: Chat room object
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func createRoomIfNedded(id: String) throws -> DMRoom? {
        var room: DMRoom?
        if let existsRoom = try DMRoom.find(id) {
            room = existsRoom
        } else {
            var newRoom = DMRoom(uniqueId: id, name: "")
            try newRoom.save()
            room = newRoom
        }
        guard let r = room else {
            throw DMFlowControllerError.unableToReadRoomParameter
        }
        _ = try Pivot<T, DMRoom>.getOrCreate(sender, r)
        return r
    }
    
    /// Parse message in context to send it to chat room participants or inform all users about sender's status.
    ///
    /// - Returns: Group of receivers to which message should be send, parsed JSON with nested sender ID.
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func parseMessage() throws -> (redirect: JSON?, receivers: [T]) {
        guard let typeChar = json.object?[DMKeys.type]?.string?.characters.first else {
            throw DMFlowControllerError.unableToReadMessageTypeParameter
        }
        guard let type = DMType(rawValue: typeChar) else {
            throw DMFlowControllerError.unknowMessageType
        }
        switch type {
        case .connected, .disconnected:
            return try deliverConnectionState(json: json, type: type)
        case .messageText:
            return try deliverMessage(json: json, type: type)
        case .beginTyping, .endTyping, .readMessage:
            return try deliverMessageState(json: json, type: type)
        }
    }
    
    /// Parse message under connection status type.
    ///
    /// - Parameters:
    ///   - json: message JSON
    ///   - type: message type, connected or disconnected
    /// - Returns: Group of receivers to which message should be send, parsed JSON with nested sender ID.
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func deliverConnectionState(json: JSON, type: DMType)  throws -> (redirect: JSON?, receivers: [T]) {
        let redirect = try composeMessage(from: json)
        if let verify = T.directMessage(sender, message: redirect, type: type) {
            let receivers: [T] = try handleStatusMessage()
            return (verify, receivers)
        }
        return (nil,[])
    }
    
    /// Parse message under text message type
    ///
    /// - Parameters:
    ///   - json: message JSON
    ///   - type: message type
    /// - Returns: Group of receivers to which message should be send, parsed JSON with nested sender ID.
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func deliverMessage(json: JSON, type: DMType)  throws -> (redirect: JSON?, receivers: [T]) {
        guard let body = json.object?[DMKeys.body]?.string else {
            throw DMFlowControllerError.unableToReadBodyParameter
        }
        guard let room = self.room else {
            throw DMFlowControllerError.unableToReadRoomParameter
        }
        try handleTextMessage(body, room: room)
        let redirect = try composeMessage(from: json)
        if let verify = T.directMessage(sender, message: redirect, type: type) {
            let receivers: [T] = try room.participants(exclude: sender)
            return (verify, receivers)
        }
        return (nil,[])
    }
    
    /// Parse message under room specific events like typing including begin, end and read message status
    ///
    /// - Parameters:
    ///   - json: message JSON
    ///   - type: message type
    /// - Returns: Group of receivers to which message should be send, parsed JSON with nested sender ID.
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func deliverMessageState(json: JSON, type: DMType)  throws -> (redirect: JSON?, receivers: [T]) {
        guard let room = self.room else {
            throw DMFlowControllerError.unableToReadRoomParameter
        }
        let redirect = try composeMessage(from: json)
        if let verify = T.directMessage(sender, message: redirect, type: type) {
            let receivers: [T] = try room.participants(exclude: sender)
            return (verify, receivers)
        }
        return (nil,[])
    }
    
    /// Handler for status message to extract receivers for this message
    ///
    /// - Returns: Group of receivers to which message should be send
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func handleStatusMessage() throws -> [T] {
        let allRooms = try sender.rooms().all()
        var receivers: [T] = []
        allRooms.forEach() {
            do {
                let participants: [T] = try $0.participants(exclude: sender)
                receivers = receivers + participants
            } catch {
                T.directMessage(log: DMLog(message: "\(error)", type: .error))
            }
        }
        return receivers
    }
    
    /// Handler for text message, save message in DataBase for historical storage.
    ///
    /// - Parameters:
    ///   - body: Text message body
    ///   - room: Chat room under message was sent
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func handleTextMessage(_ body: String, room: DMRoom) throws {
        var directive = try DMDirective(message: body)
        directive.room = room.id
        directive.owner = self.sender.id
        try directive.save()
    }
    
    /// Associate sender with message JSON
    ///
    /// - Parameter json: message JSON object
    /// - Returns: message JSON object with nested sender
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    func composeMessage(from json: JSON) throws -> JSON {
        guard let id = sender.id else {
            throw DMFlowControllerError.missingSenderId
        }
        var jsonNode = json.makeNode()
        jsonNode[DMKeys.sender] = id
        return JSON(jsonNode)
    }
}
