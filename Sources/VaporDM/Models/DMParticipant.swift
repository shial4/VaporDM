//
//  DMParticipant.swift
//  VaporDM
//
//  Created by Shial on 20/04/2017.
//
//

import Foundation
import Vapor
import Fluent

public typealias DMUser = Model & DMParticipant

public protocol DMParticipant {}

public extension DMParticipant where Self: Model {    
    public func rooms() throws -> Siblings<DMRoom> {
        return try siblings()
    }
    
    public func messages() throws -> Children<DMDirective> {
        return children(DMDirective.Constants.owner)
    }
}
