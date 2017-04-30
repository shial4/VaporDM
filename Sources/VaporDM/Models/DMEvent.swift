//
//  DMEvent.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import Foundation
import Dispatch
import JSON

public enum DMStatus {
    case success
    case failure
}

public struct DMEvent {
    public var status: DMStatus
    public var message: JSON
    
    public init<T:DMUser>(_ users: [T], message: JSON, status: DMStatus = .success) {
        self.message = message
        self.status = status
    }
    
    public func dispatch<T:DMUser>(_ sender: T) {
        DispatchQueue.global().async {
            T.directMessageEvent(self)
        }
    }
}
