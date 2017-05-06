//
//  testConnection.swift
//  VaporDM
//
//  Created by Shial on 06/05/2017.
//
//

import XCTest
@testable import VaporDM
@testable import Vapor

class testConnection: XCTestCase {
    static let allTests = [
        ("testConnection", testConnection),
        ("testConnectionEqual", testConnectionEqual),
        ("testConnectionPingTimer", testConnectionPingTimer),
        ("testConnectionPingTimerTrigger", testConnectionPingTimerTrigger),
        ("testConnectionPingTimerTriggerTwo", testConnectionPingTimerTriggerTwo),
        ]
    
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testConnection() {
        XCTAssertNotNil(DMConnection(id: "1", user: "1"))
    }
    
    func testConnectionEqual() {
        let lhs = DMConnection(id: "1", user: "1")
        let rhs = DMConnection(id: "2", user: "1")
        XCTAssertTrue(lhs == lhs, "")
        XCTAssertFalse(lhs == rhs)
    }
    
    func testConnectionPingTimer() {
        let c = DMConnection(id: "1", user: "1")
        c.ping(every: 4)
        XCTAssertTrue(c.timer != nil, "timer is nil")
    }
    
    func testConnectionPingTimerTrigger() {
        let exp = expectation(description: "Timer trigger")
        let c = DMConnection(id: "1", user: "1")
        c.ping(every: 4, callback: {
            exp.fulfill()
        })
        XCTAssertTrue(c.timer != nil, "timer is nil")
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testConnectionPingTimerTriggerTwo() {
        let exp = expectation(description: "Timer trigger")
        let exp2 = expectation(description: "Timer second trigger")
        let c = DMConnection(id: "1", user: "1")
        var count = 0
        c.ping(every: 4, callback: {
            switch count {
            case 0:
                exp.fulfill()
            case 1:
                
                exp2.fulfill()
            default:
                break
            }
            count = count + 1
        })
        XCTAssertTrue(c.timer != nil, "timer is nil")
        waitForExpectations(timeout: 10, handler: nil)
    }
}
