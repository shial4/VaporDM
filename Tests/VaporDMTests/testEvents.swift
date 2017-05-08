//
//  testEvents.swift
//  VaporDM
//
//  Created by Shial on 30/04/2017.
//
//

import XCTest
@testable import VaporDM
@testable import JSON
@testable import Vapor

class testEvents: XCTestCase {
    static let allTests = [
        ("testEvent", testEvent),
        ("testParticipantDMEvent", testParticipantDMEvent),
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
    
    func testEvent() {
        XCTAssertNotNil(DMEvent(Array<User>() ,message: JSON([:])))
    }
    
    func testParticipantDMEvent() {
        var user = try! User(id: 1)
        try! user.save()
        User.directMessageEvent(DMEvent([] ,message: JSON([:])))
        XCTAssertTrue(true)
    }
}
