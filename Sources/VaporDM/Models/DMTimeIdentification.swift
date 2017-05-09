//
//  DMTimeIdentification.swift
//  VaporDM
//
//  Created by Shial on 09/05/2017.
//
//

import Foundation
/// Time identification, to specify create date and update date.
public struct DMTimeIdentification {
    /// Chat room created date
    public var created: Date = Date()
    /// Chat room updated date
    public var updated: Date = Date()
    /// Default public initializer
    public init() {}
}
