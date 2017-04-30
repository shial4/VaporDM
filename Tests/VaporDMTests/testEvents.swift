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

class testEvents: XCTestCase {
    static let allTests = [
        ("testEvent", testEvent),
    ]

    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEvent() {
        XCTAssertNotNil(DMEvent(Array<User>() ,message: JSON([:])))
    }
}
