//
//  EntityExtension.swift
//  VaporDM
//
//  Created by Shial on 08/05/2017.
//
//

import Foundation
import Fluent

extension Entity {
    /// return key string for object under  Pivot
    var pivotKey: String {
        return "\(Self.name)_\(Self.idKey)"
    }
}
