//
//  testDirectMessage.swift
//  VaporDM
//
//  Created by Shial on 28/04/2017.
//
//

import XCTest
@testable import Vapor
@testable import Fluent
@testable import VaporDM

class testDirectMessage: XCTestCase {
    
    static let allTests = [
        ("testTextMessageHandling", testTextMessageHandling),
        ("testExistingRoomObjectFromMessage", testExistingRoomObjectFromMessage),
        ("testNewRoomObjectFromMessage", testNewRoomObjectFromMessage),
        ("testMessageHistory", testMessageHistory),
        ("testRoomParticipants", testRoomParticipants),
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
    
    func testTextMessageHandling() {
        var user = try! User(id: 1)
        try! user.save()
        let testMessage = try! JSON([
            "room":"1234",
            "type":"M",
            "body":"message"]).makeBytes().string()
        XCTAssertNotNil(testMessage)
        do {
            let message = try DirectMessage(sender: user, message: testMessage)
            let response: (redirect: JSON, receivers: [User]) = try message.parseMessage()
            let room: String? = try? response.redirect.extract("room")
            let type: String? = try? response.redirect.extract("type")
            let body: String? = try? response.redirect.extract("body")
            let sender: String? = try? response.redirect.extract("sender")
            XCTAssertNotNil(room)
            XCTAssertNotNil(type)
            XCTAssertNotNil(body)
            XCTAssertNotNil(sender)
            XCTAssertTrue(room == "1234", "Room do not match expected value")
            XCTAssertTrue(type == "M", "Type do not match expected value")
            XCTAssertTrue(body == "message", "Message do not match expected value")
            XCTAssertTrue(sender == "1", "User do not match expected value")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExistingRoomObjectFromMessage() {
        var user = try! User(id: 1)
        try! user.save()
        let testMessage = try! JSON([
            "room":"1234",
            "type":"M",
            "body":"first"]).makeBytes().string()
        XCTAssertNotNil(testMessage)
        do {
            let message = try DirectMessage(sender: user, message: testMessage)
            let _: (redirect: JSON, receivers: [User]) = try message.parseMessage()
            let room = try user.rooms().filter(DMRoom.Constants.uniqueId, "1234").all()
            XCTAssertNotNil(room)
            XCTAssertTrue(room.count == 1, "Rooms count wrong")
        } catch {
            XCTFail(error.localizedDescription)
        }
        let testMessage2 = try! JSON([
            "room":"1234",
            "type":"M",
            "body":"second"]).makeBytes().string()
        XCTAssertNotNil(testMessage2)
        do {
            let message = try DirectMessage(sender: user, message: testMessage2)
            let _: (redirect: JSON, receivers: [User]) = try message.parseMessage()
            let room = try user.rooms().filter(DMRoom.Constants.uniqueId, "1234").all()
            XCTAssertNotNil(room)
            XCTAssertTrue(room.count == 1, "Rooms count wrong")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testNewRoomObjectFromMessage() {
        var user = try! User(id: 1)
        try! user.save()
        let testMessage = try! JSON([
            "room":"2",
            "type":"M",
            "body":"first"]).makeBytes().string()
        XCTAssertNotNil(testMessage)
        let testMessage2 = try! JSON([
            "room":"4321",
            "type":"M",
            "body":"second"]).makeBytes().string()
        XCTAssertNotNil(testMessage2)
        do {
            let message = try DirectMessage(sender: user, message: testMessage)
            let _: (redirect: JSON, receivers: [User]) = try message.parseMessage()
            let room = try user.rooms().filter(DMRoom.Constants.uniqueId, "2").all()
            XCTAssertNotNil(room)
            XCTAssertTrue(room.count == 1, "Rooms count wrong")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMessageHistory() {
        var user = try! User(id: 1)
        try! user.save()
        let testMessage = try! JSON([
            "room":"2",
            "type":"M",
            "body":"first"]).makeBytes().string()
        XCTAssertNotNil(testMessage)
        let testMessage2 = try! JSON([
            "room":"4321",
            "type":"M",
            "body":"second"]).makeBytes().string()
        XCTAssertNotNil(testMessage2)
        do {
            let _: (redirect: JSON, receivers: [User]) = try DirectMessage(sender: user, message: testMessage).parseMessage()
            let _: (redirect: JSON, receivers: [User]) = try DirectMessage(sender: user, message: testMessage2).parseMessage()
            let messages: [DMDirective] = try user.messages().all()
            XCTAssertNotNil(messages)
            XCTAssertTrue(messages.count == 2, "Messages count is wrong")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRoomParticipants() {
        do {
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            var room = DMRoom(uniqueId: UUID().uuidString, name: "Room")
            try room.save()
            let pivot = try Pivot<User, DMRoom>.getOrCreate(user1, room)
            let pivot1 = try Pivot<User, DMRoom>.getOrCreate(user2, room)
            let pivot2 = try Pivot<User, DMRoom>.getOrCreate(user3, room)
            XCTAssertNotNil(pivot)
            XCTAssertNotNil(pivot1)
            XCTAssertNotNil(pivot2)
            let receivers: [User] = try room.participants()
            XCTAssertTrue(receivers.count == 3, "Rooms wrong participants number")
            XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == user1.id }), "Rooms missing participant id:1")
            XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == user2.id }), "Rooms missing participant id:2")
            XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == user3.id }), "Rooms missing participant id:3")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
