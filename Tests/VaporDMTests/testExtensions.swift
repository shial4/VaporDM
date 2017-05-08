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
        ("testPivotGetOrCreateNilId1", testPivotGetOrCreateNilId1),
        ("testPivotGetOrCreateNilId2", testPivotGetOrCreateNilId2),
        ("testPivotGetOrCreateNilId3", testPivotGetOrCreateNilId3),
        ("testPivotGetOrCreateNilId4", testPivotGetOrCreateNilId4),
        ("testRemoveUserFromArray", testRemoveUserFromArray),
        ("testRemovePivot", testRemovePivot),
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
    
    //MARK: Pivot Extension
    func testPivotLeftKey() {
        let user = try! User(id: 11)
        XCTAssert(user.pivotKey == "\(User.name)_\(User.idKey)", user.pivotKey)
    }
    
    func testPivotRightKey() {
        let room = DMRoom(uniqueId: "uniq", name: "")
        XCTAssert(room.pivotKey == "\(DMRoom.name)_\(DMRoom.idKey)", room.pivotKey)
    }
    
    func testPivotGetOrCreate() {
        do {
            var user = try User(id: 1)
            try user.save()
            var room = DMRoom(uniqueId: UUID().uuidString, name: "RoomName")
            try room.save()
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateExisting() {
        do {
            var user = try User(id: 1)
            try user.save()
            var room = DMRoom(uniqueId: UUID().uuidString, name: "RoomName")
            try room.save()
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot)
            let pivot2 = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot2)
            XCTAssert(pivot2.id == pivot.id)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateNilId1() {
        do {
            let user = try User(id: 1)
            let room = DMRoom(uniqueId: UUID().uuidString, name: "RoomName")
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNil(pivot)
        } catch RelationError.noIdentifier {
            XCTAssert(true, "no identifier")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateNilId2() {
        do {
            let user = try User(id: 1)
            let room = DMRoom(uniqueId: UUID().uuidString, name: "RoomName")
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNil(pivot)
        } catch RelationError.noIdentifier {
            XCTAssert(true, "no identifier")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateNilId3() {
        do {
            let user = try User(id: 1)
            var room = DMRoom(uniqueId: UUID().uuidString, name: "RoomName")
            try room.save()
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNotNil(pivot)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPivotGetOrCreateNilId4() {
        do {
            var user = try User(id: 1)
            try user.save()
            let room = DMRoom(uniqueId: UUID().uuidString, name: "RoomName")
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user, room)
            XCTAssertNil(pivot)
        } catch RelationError.noIdentifier {
            XCTAssert(true, "no identifier")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRemoveUserFromArray() {
        do {
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            var array = [user1,user2,user3]
            if let removed: User = array.remove("2") {
                XCTAssert(removed.id == 2, "Wrong user removed")
            }
            XCTAssert(array.count == 2, "wrong array count")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRemovePivot() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            var user4 = try User(id: 4)
            try user4.save()
            try room.save()
            _ = try Pivot<User, DMRoom>.getOrCreate(user1, room)
            _ = try Pivot<User, DMRoom>.getOrCreate(user2, room)
            _ = try Pivot<User, DMRoom>.getOrCreate(user3, room)
            _ = try Pivot<User, DMRoom>.getOrCreate(user4, room)
            try Pivot<User, DMRoom>.remove(user1, room)
            let participants: [User] = try room.participants()
            print(participants.map({$0.id ?? "-"}))
            XCTAssert(participants.count == 3, "wrong array count")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
