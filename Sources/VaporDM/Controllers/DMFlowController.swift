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

public struct DMKeys {
    static let room = "room"
    static let type = "type"
    static let body = "body"
    static let sender = "sender"
}

public enum DMType: Character {
    case connected = "C"
    case disconnected = "D"
    case messageText = "M"
    case beginTyping = "B"
    case endTyping = "E"
    case readMessage = "R"
}

struct DMFlowController<T: DMUser> {
    var room: DMRoom?
    var sender: T
    var json: JSON
    
    init(sender: T, message json: JSON) throws {
        self.json = json
        self.sender = sender
        if let room = json.object?[DMKeys.room]?.string  {
            self.room = try createRoomIfNedded(id: room)
        }
    }
    
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
    
    fileprivate func deliverConnectionState(json: JSON, type: DMType)  throws -> (redirect: JSON?, receivers: [T]) {
        let redirect = try composeMessage(from: json)
        if let verify = T.directMessage(sender, message: redirect, type: type) {
            let receivers: [T] = try handleStatusMessage()
            return (verify, receivers)
        }
        return (nil,[])
    }
    
    fileprivate func deliverMessage(json: JSON, type: DMType)  throws -> (redirect: JSON?, receivers: [T]) {
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
    
    fileprivate func deliverMessageState(json: JSON, type: DMType)  throws -> (redirect: JSON?, receivers: [T]) {
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
    
    fileprivate func handleStatusMessage() throws -> [T] {
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
    
    fileprivate func handleTextMessage(_ body: String, room: DMRoom) throws {
        var directive = try DMDirective(message: body)
        directive.room = room.id
        directive.owner = self.sender.id
        try directive.save()
    }
    
    fileprivate func composeMessage(from json: JSON) throws -> JSON {
        guard let id = sender.id else {
            throw DMFlowControllerError.missingSenderId
        }
        var jsonNode = json.makeNode()
        jsonNode[DMKeys.sender] = id
        return JSON(jsonNode)
    }
}
