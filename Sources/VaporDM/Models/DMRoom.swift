//
//  DMRoom.swift
//  VaporDM
//
//  Created by Shial on 19/04/2017.
//
//

import Foundation
import Vapor
import Fluent

public final class DMRoom {
    public static var entity = "DMRoom"
    public var exists = false
    
    public var id: Node?
    
    struct Constants {
        static let id = "id"
        static let created = "created"
        static let updated = "updated"
        static let name = "name"
    }
    
    public var name: String
    public var created: Date = Date()
    public var updated: Date = Date()
    
    public init(id: NodeRepresentable, name: String) throws {
        self.id = try id.makeNode()
        self.name = name
    }
    
    public init(node: Node, in context: Context) throws {
        do { id = try node.extract(Constants.id) } catch {}
        do { created = try node.extract(Constants.created,
                                        transform: Date.init(timeIntervalSince1970:)) } catch {}
        do { updated = try node.extract(Constants.updated,
                                        transform: Date.init(timeIntervalSince1970:)) } catch {}
        name = try node.extract(Constants.name)
    }
}

extension DMRoom: Model {
    public func makeNode(context: Context) throws -> Node {
        return try Node(node: [Constants.id: id,
                               Constants.name: name,
                               Constants.created: created.timeIntervalSince1970,
                               Constants.updated: updated.timeIntervalSince1970])
    }
}

extension DMRoom: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(DMRoom.entity, closure: { (room) in
            room.id()
            room.string(Constants.name)
            room.double(Constants.created)
            room.double(Constants.updated)
        })
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete(DMRoom.entity)
    }
}

extension DMRoom {
    public func messages() throws -> [DMDirective] {
        return try children().all()
    }
    public func messages(from: Double, to: Double? = nil) throws -> [DMDirective] {
        guard let to = to else {
            return try children().filter(DMDirective.Constants.created, .greaterThan, from).all()
        }
        return try children().filter(DMDirective.Constants.created, .greaterThan, from).filter(DMDirective.Constants.created, .lessThan, to).all()
    }
    public func participant<T:DMUser>() throws -> Siblings<T> {
        return try siblings()
    }
}
