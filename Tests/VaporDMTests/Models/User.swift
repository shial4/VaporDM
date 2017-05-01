//
//  User.swift
//  VaporDM
//
//  Created by Shial on 19/04/2017.
//
//

import Foundation
@testable import Vapor
@testable import Fluent
@testable import VaporDM

public final class User {
    public static var entity = "Users"
    public var exists = false
    
    public var id: Node?
    
    struct Constants {
        static let id = "id"
        static let created = "created"
        static let updated = "updated"
    }
    
    public var created: Date = Date()
    public var updated: Date = Date()
    
    public init(id: NodeRepresentable) throws {
        self.id = try id.makeNode()
    }
    
    public init(node: Node, in context: Context) throws {
        do { id = try node.extract(Constants.id) } catch {}
        do { created = try node.extract(Constants.created,
                                        transform: Date.init(timeIntervalSince1970:)) } catch {}
        do { updated = try node.extract(Constants.updated,
                                        transform: Date.init(timeIntervalSince1970:)) } catch {}
    }
}

extension User: Model {
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [Constants.id: id,
                               Constants.created: created.timeIntervalSince1970,
                               Constants.updated: updated.timeIntervalSince1970])
    }
}

extension User: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(User.entity, closure: { (user) in
            user.id()
            user.double(Constants.created)
            user.double(Constants.updated)
        })
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete(User.entity)
    }
}

extension User: DMParticipant {
    public static func directMessage(_ message: JSON, type: DMType) -> JSON? {
        if let senderId: String = try? message.extract(DMKeys.sender) {
            print(senderId)
            
        }
        return message
    }
    public static func directMessageLog(_ log: DMLog) {
        print(log.message)
        
    }
    public static func directMessageEvent(_ event: DMEvent) {
        let users: [Model] = event.users
        print(users)
    }
}
