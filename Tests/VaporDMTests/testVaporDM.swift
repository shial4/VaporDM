//
//  testVaporGCM.swift
//  VaporGCM
//
//  Created by Shial on 11/04/2017.
//
//

import XCTest
@testable import Vapor
@testable import HTTP
@testable import VaporDM

class testVaporDM: XCTestCase {
    static let allTests = [
        ("testDM", testDM)
    ]
    
    var drop: Droplet! = nil
    
    override func setUp() {
        super.setUp()
        drop = try! Droplet.makeTestDroplet()
    }
    
    override func tearDown() {
        super.tearDown()
        drop = nil
    }
    
    func testDM() {
        XCTAssertNil(nil)
    }
}
