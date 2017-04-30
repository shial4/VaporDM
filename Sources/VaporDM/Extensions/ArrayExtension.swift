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
