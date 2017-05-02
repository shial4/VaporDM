//
//  DMEvent.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import Foundation
import Vapor
import JSON

public enum DMStatus {
    case success
    case failure
}

public struct DMEvent<T: DMParticipant> {
    public var status: DMStatus
    public var message: JSON
    public var users: [T]
    
    public init(_ users: [T], message: JSON, status: DMStatus = .success) {
        self.message = message
        self.status = status
        self.users = users
    }
}
