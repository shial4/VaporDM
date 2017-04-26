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
    
    public var description: String {
        switch self {
        case .jsonWrongContent:
            return ""
        case .unableToReadRoomParameter:
            return ""
        case .unableToReadMessageTypeParameter:
            return ""
        case .unknowMessageType:
            return ""
        case .unableToReadBodyParameter:
            return ""
        case .missingSenderId:
            return ""
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

struct DirectMessage {
    var room: DMRoom
    var sender: DMUser
    var json: JSON
    
    init<T:DMUser>(sender: T, message: String) throws {
        self.json = try JSON(bytes: Array(message.utf8))
        guard let room = json.object?["room"]?.string else {
            throw DirectMessageError.unableToReadRoomParameter
        }
        self.sender = sender
        if let existsRoom = try DMRoom.find(room) {
                self.room = existsRoom
        } else {
            var newRoom = try DMRoom(id: room, name: "")
            try newRoom.save()
            self.room = newRoom
        }
    }
    
    func parseMessage<T:DMUser>() throws -> (redirect: JSON, receivers: [T]) {
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
        let receivers: [T] = try roomReceivers()
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
        return JSON([json, JSON(["sender":id])])
    }
    
    fileprivate func roomReceivers<T:DMUser>() throws -> [T] {
        guard let id = sender.id else {
            throw DirectMessageError.missingSenderId
        }
        return try room.participant().filter(T.idKey, .notEquals, id).all()
    }
}
