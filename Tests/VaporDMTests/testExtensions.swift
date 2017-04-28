//
//  testExtensions.swift
//  VaporDM
//
//  Created by Shial on 28/04/2017.
//
//

import XCTest
@testable import VaporDM
@testable import Vapor
@testable import Fluent

class testExtensions: XCTestCase {
    
    static let allTests = [
        ("testPivotLeftKey", testPivotLeftKey),
        ("testPivotRightKey", testPivotRightKey),
        ("testPivotGetOrCreate", testPivotGetOrCreate),
        ("testPivotGetOrCreateExisting", testPivotGetOrCreateExisting),
        ("testPivotGetOrCreateNilId", testPivotGetOrCreateNilId)
        ]
    
    var drop: Droplet! = nil
    var dm: VaporDM<User>? = nil
    
    override func setUp() {
        super.setUp()
        drop = try! Droplet.makeTestDroplet()
        dm = VaporDM(for: drop)
        try! drop.revertAndPrepareDatabase()
    }
    
    override func tearDown() {
        super.tearDown()
        try! drop.revertDatabase()
        drop = nil
    }
    
    //MARK: Pivot Extension
    func testPivotLeftKey() {
        let leftKey = Pivot<User, DMRoom>.leftKey
        XCTAssert(leftKey == "\(User.name)_\(User.idKey)")
    }
    
    func testPivotRightKey() {
        let rightKey = Pivot<User, DMRoom>.rightKey
        XCTAssert(rightKey == "\(DMRoom.name)_\(DMRoom.idKey)")
    }
    
    func testPivotGetOrCreate() {
        do {
            let user = try User(id: 1)
            let room = try DMRoom(id: 1, name: "RoomName")
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateExisting() {
        do {
            let user = try User(id: 1)
            let room = try DMRoom(id: 1, name: "RoomName")
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot)
            let pivot2 = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot2)
            XCTAssert(pivot2.id == pivot.id)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateNilId() {
        do {
            let user = try User(id: 1)
            user.id = nil
            let room = try DMRoom(id: 1, name: "RoomName")
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNil(pivot)
        } catch RelationError.noIdentifier {
            XCTAssert(true, "no identifier")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
