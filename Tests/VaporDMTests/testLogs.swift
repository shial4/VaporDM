//
//  testLogs.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import XCTest
@testable import VaporDM
@testable import JSON
@testable import Vapor

class testLogs: XCTestCase {
    static let allTests = [
        ("testEvent", testLogs),
        ("testParticipantDMLog", testParticipantDMLog),
        ]
    
    
    var drop: Droplet! = nil
    var dm: VaporDM<User>? = nil
    
    override func setUp() {
        super.setUp()
        drop = try! Droplet.makeTestDroplet()
        dm = VaporDM(for: drop)
        try! drop.runCommands()
        try! drop.revertAndPrepareDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
        try! drop.revertDatabase()
        drop = nil
    }
    
    func testLogs() {
        XCTAssertNotNil(DMLog(message: "error message", type: .error))
    }
    
    func testParticipantDMLog() {
        var user = try! User(id: 1)
        try! user.save()
        User.directMessage(log: DMLog(message: "error", type: .error))
        XCTAssertTrue(true)
    }
}
