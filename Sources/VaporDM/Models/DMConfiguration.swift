//
//  DMConfiguration.swift
//  VaporDM
//
//  Created by Shial on 06/05/2017.
//
//

import Foundation

/// VaporDM configuration. Used to keep connection open.
public protocol DMConfiguration {
    /// Ping interval to hold connection open. Specify in seconds. If not defined. Socket is not ping.
    var pingIterval: Int? { get }
}

/// Default VaporDM configuration. Ping interval set to 10 seconds in between socket pings.
struct DMDefaultConfiguration: DMConfiguration {
    /// Ping interval set to 10 sec.
    var pingIterval: Int? {
        return 10
    }
}
