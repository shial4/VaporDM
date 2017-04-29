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
        ("testDM", testDM),
        ("testConnection", testConnection)
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

    func testConnection() {
        XCTAssertNotNil(dm)
        /*
        var user = try! User(id: 1)
        try! user.save()
        let expectation = self.expectation(description: "connecting to chat")
        do {
            try WebSocket.connect(to: "ws://0.0.0.0:8080/chat/service/1") { ws in
                ws.onText = { ws, text in
                    print("[CONNECTED] - \(text)")
                    expectation.fulfill()
                }
                ws.onClose = { ws, _, _, _ in
                    print("\n[CLOSED]\n")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
 */
    }
}
