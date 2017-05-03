//
//  ArrayExtension.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import Foundation
import Fluent

extension Array where Element: DMUser {
    /// Removes object from array based on Element type correcponding to Fluent's Model and VaporDM's DMParticipants
    ///
    /// - Parameter id: DataBase model's id
    /// - Returns: Removed Model from array if any
    mutating public func remove(_ id: String) -> Element? {
        var element: Element?
        self = self.filter() {
            guard $0.id?.string != id else {
                element = $0
                return false
            }
            return true
        }
        return element
    }
}
