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
    
    func testDM() {
        XCTAssertNotNil(dm)
    }
}
