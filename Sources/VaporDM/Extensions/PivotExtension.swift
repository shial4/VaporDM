//
//  PivotExtension.swift
//  VaporDM
//
//  Created by Shial on 28/04/2017.
//
//

import Fluent

extension Pivot where First: DMParticipant, First: DMUser, Second: DMRoom {
    /// return key string for left Entity object under this Pivot
    static var leftKey: String {
        return "\(left.name)_\(left.idKey)"
    }
    
    /// return key string for right Entity object under this Pivot
    static var rightKey: String {
        return "\(right.name)_\(right.idKey)"
    }
    
    /// Create Pivot between two entities if needed. Otherwise return existing one
    ///
    /// - Parameters:
    ///   - first: Entity object between pivot should be created
    ///   - second: Entity object between pivot should be created
    /// - Returns: Pivot object between first and second Entity objects
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    public static func getOrCreate(_ first: Entity, _ second: Entity) throws -> Pivot {
        var pivot: Pivot<First, Second>?
        guard let firstId = first.id, let secondId = second.id else {
            throw RelationError.noIdentifier
        }
        let x = try query().filter(leftKey, firstId).filter(rightKey, secondId).all()
        if x.isEmpty {
            pivot = self.init(first, second)
        } else {
            pivot = x.first
        }
        try pivot?.save()
        guard let p = pivot else {
            throw DMFlowControllerError.unableToGetOrCreatePivot
        }
        return p
    }
    
    /// Create Pivot between two entities if more then one, remove them all
    ///
    /// - Parameters:
    ///   - first: Entity object between pivot should be removed
    ///   - second: Entity object between pivot should be removed
    /// - Throws: If anything bad occurred during this method, error message will be thrown
    public static func remove(_ first: Entity, _ second: Entity) throws {
        guard let firstId = first.id, let secondId = second.id else {
            throw RelationError.noIdentifier
        }
        try query().filter(leftKey, firstId).filter(rightKey, secondId).delete()
    }
}
