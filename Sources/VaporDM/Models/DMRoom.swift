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
    public var exists = false
    /// Chat room id
    public var id: Node?
    
    struct Constants {
        static let id = "id"
        static let uniqueId = "uniqueid"
        static let created = "created"
        static let updated = "updated"
        static let name = "name"
    }
    /// Chat room name
    public var name: String
    /// Char room UUID
    public var uniqueId: String
    /// Time identification
    public var time: DMTimeIdentification = DMTimeIdentification()
    /// Initialize object with UUID and name
    ///
    /// - Parameters:
    ///   - uniqueId: UUID of chat room
    ///   - name: Name of char room
    public init(uniqueId: String, name: String) {
        self.uniqueId = uniqueId
        self.name = name
    }
    /// Initialize object for DataBase context
    ///
    /// - Parameter node: node with data
    /// - Throws: Error if something goes wrong
    init(forDatabase node: Node) throws {
        id = try node.extract(Constants.id)
        time.created = try node.extract(Constants.created,
                                   transform: Date.init(timeIntervalSince1970:))
        time.updated = try node.extract(Constants.updated,
                                   transform: Date.init(timeIntervalSince1970:))
        name = try node.extract(Constants.name)
        uniqueId = try node.extract(Constants.uniqueId)
    }
    /// Initialize object for all other contexts
    ///
    /// - Parameter node: node with data
    /// - Throws: Error if something goes wrong
    init(forDefault node: Node) throws {
        id = try? node.extract(Constants.id)
        name = try node.extract(Constants.name)
        uniqueId = try node.extract(Constants.uniqueId)
    }
    /// Convenience initialize object for context
    ///
    /// - Parameters:
    ///   - node: node with data
    ///   - context: context information for init
    /// - Throws: Error if something goes wrong
    convenience public init(node: Node, in context: Context) throws {
        switch context {
        case is DatabaseContext:
            try self.init(forDatabase: node)
        default:
            try self.init(forDefault: node)
        }
    }
}

extension DMRoom: Model {
    public func makeNode(context: Context) throws -> Node {
        var node: [String: Node] = [:]
        node[Constants.id] = id
        node[Constants.name] = name.makeNode()
        node[Constants.uniqueId] = uniqueId.lowercased().makeNode()
        node[Constants.created] = time.created.timeIntervalSince1970.makeNode()
        node[Constants.updated] = time.updated.timeIntervalSince1970.makeNode()
        return try node.makeNode()
    }
}

extension DMRoom: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(DMRoom.entity, closure: { (room) in
            room.id()
            room.string(Constants.uniqueId, unique: true)
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
    /// Return all messages under this chat room
    ///
    /// - Returns: array of messages
    /// - Throws: Error if something goes wrong
    public func messages() throws -> [DMDirective] {
        return try children(DMDirective.Constants.room).all()
    }
    /// Query messages from this chat room between given Dates in TimeIntervals
    ///
    /// - Parameters:
    ///   - from: TimeInterval from which messages should be query
    ///   - to: TimeInterval to which messages should be query
    /// - Returns: direct messages array for this chat room
    /// - Throws: Error if something goes wrong
    public func messages(from: Double? = nil, to: Double? = nil) throws -> [DMDirective] {
        switch (from, to) {
        case let (from, to)  as (Double, Double):
            return try children(DMDirective.Constants.room).filter(DMDirective.Constants.created, .greaterThan, from).filter(DMDirective.Constants.created, .lessThan, to).all()
        case let (from, nil) as (Double, Double?):
            return try children(DMDirective.Constants.room).filter(DMDirective.Constants.created, .greaterThan, from).all()
        case let (nil, to) as (Double?, Double):
            return try children(DMDirective.Constants.room).filter(DMDirective.Constants.created, .lessThan, to).all()
        default:
            return try children(DMDirective.Constants.room).all()
        }
    }
    /// Get chat room sibling with you Fluent model associated with VaporDM
    ///
    /// - Returns: Sibling between DMRoom and you Fluent's model
    /// - Throws: Error if something goes wrong
    public func participant<T:DMUser>() throws -> Siblings<T> {
        return try siblings()
    }
    /// Get chat room participants
    ///
    /// - Parameter sender: If sender is specify, will exclude him from participants
    /// - Returns: Chat room participants
    /// - Throws: Error if something goes wrong
    public func participants<T:DMUser>(exclude sender: T? = nil) throws -> [T] {
        guard let id = sender?.id else {
            return try participant().all()
        }
        return try participant().filter(T.idKey, .notEquals, id).all()
    }
}

extension DMRoom {
    /// Find char toom by UUID
    ///
    /// - Parameter uniqueId: UUID of chat room
    /// - Returns: Chat room object if exist with this UUID
    /// - Throws: Error if something goes wrong
    public class func find(_ uniqueId: String) throws -> DMRoom? {
        guard let _ = database else { return nil }
        return try DMRoom.query().filter(Constants.uniqueId, .equals, uniqueId.lowercased()).first()
    }
}
