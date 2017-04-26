//
//  DMDirective.swift
//  VaporDM
//
//  Created by Shial on 19/04/2017.
//
//

import Foundation
import Vapor
import Fluent

public final class DMDirective {
    public static var entity = "DMDirective"
    public var exists = false
    
    public var id: Node?
    public var room: Node?
    public var owner: Node?
    
    struct Constants {
        static let id = "id"
        static let room = "roomId"
        static let owner = "ownerId"
        static let created = "created"
        static let updated = "updated"
        static let message = "message"
        static let isSeen = "seen"
        static let isSystemMessage = "systemMessage"
    }
    
    public var message: String
    public var isSystemMessage: Bool
    public var isSeen: Bool = false
    public var created: Date = Date()
    public var updated: Date = Date()
    
    public init(message: String, system: Bool = false) throws {
        self.message = message
        self.isSystemMessage = system
    }
    
    public init(node: Node, in context: Context) throws {
        do { id = try node.extract(Constants.id) } catch {}
        do { room = try node.extract(Constants.room) } catch {}
        do { owner = try node.extract(Constants.owner) } catch {}
        do { created = try node.extract(Constants.created,
                                        transform: Date.init(timeIntervalSince1970:)) } catch {}
        do { updated = try node.extract(Constants.updated,
                                        transform: Date.init(timeIntervalSince1970:)) } catch {}
        message = try node.extract(Constants.message)
        isSystemMessage = try node.extract(Constants.isSystemMessage)
        isSeen = try node.extract(Constants.isSeen)
    }
}

extension DMDirective: Model {
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [Constants.id: id,
                               Constants.room: room,
                               Constants.message: message,
                               Constants.created: created.timeIntervalSince1970,
                               Constants.updated: updated.timeIntervalSince1970])
    }
}

extension DMDirective: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(DMDirective.entity, closure: { (directive) in
            directive.id()
            directive.parent(idKey: Constants.room, optional: false)
            directive.parent(idKey: Constants.owner, optional: false)
            directive.string(Constants.message)
            directive.bool(Constants.isSystemMessage)
            directive.bool(Constants.isSeen)
            directive.double(Constants.created)
            directive.double(Constants.updated)
        })
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete(DMDirective.entity)
    }
}

extension DMDirective {
    public func getRoom() throws -> DMRoom? {
        return try parent(room).first()
    }
    public func getOwner<T:DMUser>() throws -> T? {
        return try parent(owner).first()
    }
}
