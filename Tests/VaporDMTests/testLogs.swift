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

class testLogs: XCTestCase {
    static let allTests = [
        ("testEvent", testLogs),
        ]
    
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLogs() {
        XCTAssertNotNil(DMLog(message: "error message", type: .error))
    }
}
