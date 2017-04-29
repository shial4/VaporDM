//
//  DirectMessage.swift
//  VaporDM
//
//  Created by Shial on 18/04/2017.
//
//

import Foundation
import Vapor
import Fluent

public enum DirectMessageError: CustomStringConvertible, Error {
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

private enum Type: Character {
    case connected = "C"
    case disconnected = "D"
    case messageText = "M"
    case beginTyping = "B"
    case endTyping = "E"
    case readMessage = "R"
}

struct DirectMessage<T: DMUser> {
    var room: DMRoom
    var sender: T
    var json: JSON
    
    init(sender: T, message: String) throws {
        self.json = try JSON(bytes: Array(message.utf8))
        guard let room = json.object?["room"]?.string else {
            throw DirectMessageError.unableToReadRoomParameter
        }
        self.sender = sender
        if let existsRoom = try DMRoom.find(room) {
                self.room = existsRoom
        } else {
            var newRoom = DMRoom(uniqueId: room, name: "")
            try newRoom.save()
            self.room = newRoom
        }
        _ = try Pivot<T, DMRoom>.getOrCreate(sender, self.room)
    }
    
    func parseMessage() throws -> (redirect: JSON, receivers: [T]) {
        guard let typeChar = json.object?["type"]?.string?.characters.first else {
            throw DirectMessageError.unableToReadMessageTypeParameter
        }
        guard let type = Type(rawValue: typeChar) else {
            throw DirectMessageError.unknowMessageType
        }
        
        switch type {
        case .connected:
            break
        case .disconnected:
            break
        case .messageText:
            guard let body = json.object?["body"]?.string else {
                throw DirectMessageError.unableToReadBodyParameter
            }
            try handleTextMessage(body)
        case .beginTyping:
            break
        case .endTyping:
            break
        case .readMessage:
            break
        }
        let redirect = try composeMessage(from: json)
        let receivers: [T] = try room.participants(exclude: sender)
        return (redirect, receivers)
    }
    
    fileprivate func handleTextMessage(_ body: String) throws {
        var directive = try DMDirective(message: body)
        directive.room = self.room.id
        directive.owner = self.sender.id
        try directive.save()
    }
    
    fileprivate func composeMessage(from json: JSON) throws -> JSON {
        guard let id = sender.id else {
            throw DirectMessageError.missingSenderId
        }
        var jsonNode = json.makeNode()
        jsonNode["sender"] = id
        return JSON(jsonNode)
    }
}
