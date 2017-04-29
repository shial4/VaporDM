//
//  PivotExtension.swift
//  VaporDM
//
//  Created by Shial on 28/04/2017.
//
//

import Fluent

extension Pivot where First: DMParticipant, First: DMUser, Second: DMRoom {
    static var leftKey: String {
        return "\(left.name)_\(left.idKey)"
    }
    static var rightKey: String {
        return "\(right.name)_\(right.idKey)"
    }
    
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
            throw DirectMessageError.unableToGetOrCreatePivot
        }
        return p
    }
}
