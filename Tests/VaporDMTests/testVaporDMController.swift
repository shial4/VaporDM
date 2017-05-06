//
//  testVaporDMController.swift
//  VaporDM
//
//  Created by Shial on 29/04/2017.
//
//

import XCTest
@testable import Vapor
@testable import HTTP
@testable import Fluent
@testable import VaporDM

class testVaporDMController: XCTestCase {
    
    static let allTests = [
        ("testCreateRoom", testCreateRoom),
        ("testCreateRoomWithExistingUUID", testCreateRoomWithExistingUUID),
        ("testCreateRoomWithParticipants", testCreateRoomWithParticipants),
        ("testGetRoom", testGetRoom),
        ("testGetRoomFailure", testGetRoomFailure),
        ("testAddUserToRoom", testAddUserToRoom),
        ("testAddUsersToRoom", testAddUsersToRoom),
        ("testAddUsersToRoomWithVeryfication", testAddUsersToRoomWithVeryfication),
        ("testGetRoomParticipant", testGetRoomParticipant),
        ("testGetParticipantRooms", testGetParticipantRooms),
        ("testGetNotFoundRoomHistory", testGetNotFoundRoomHistory),
        ("testGetRoomHistory", testGetRoomHistory),
        ("testConfiguration", testConfiguration),
        ("testConfigurationInterval", testConfigurationInterval),
        ("testErrorMessages", testErrorMessages),
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
    
    func testCreateRoom() {
        let roomUniqueId = UUID().uuidString
        let request = try! Request(method: .post, uri: "/chat/room")
        request.headers["Content-Type"] = "application/json"
        request.body = JSON([
            "uniqueid":Node(roomUniqueId),
            "name":"CreateRoomTest"
            ]).makeBody()
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        guard let body = response.body.bytes else {
            XCTFail()
            return
        }
        let node = try! JSON(bytes: body)
        let uniqueID = node["uniqueid"]
        guard let id = uniqueID?.string, id == roomUniqueId.lowercased() else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode == 200)
    }
    
    func testCreateRoomWithExistingUUID() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            try room.save()
        } catch {
            XCTFail(error.localizedDescription)
        }
        let request = try! Request(method: .post, uri: "/chat/room")
        request.headers["Content-Type"] = "application/json"
        request.body = JSON([
            "uniqueid":Node(roomUniqueId),
            "name":"CreateRoomTest"
            ]).makeBody()
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode != 200)
    }
    
    func testCreateRoomWithParticipants() {
        var array: [User] = []
        do {
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            array = [user1,user2,user3]
        } catch {
            XCTFail(error.localizedDescription)
        }
        let roomUniqueId = UUID().uuidString
        let request = try! Request(method: .post, uri: "/chat/room")
        request.headers["Content-Type"] = "application/json"
        request.body = JSON([
            "uniqueid":Node(roomUniqueId),
            "name":"CreateRoomTest",
            "participants":["1","2","3"]
            ]).makeBody()
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        guard let body = response.body.bytes else {
            XCTFail()
            return
        }
        let node = try! JSON(bytes: body)
        let uniqueID = node["uniqueid"]
        guard let id = uniqueID?.string, id == roomUniqueId.lowercased() else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode == 200)
        do {
            if let receivers: [User] = try DMRoom.find(roomUniqueId)?.participants() {
                XCTAssertTrue(receivers.count == 3)
                for u in array {
                    let p = try User(node: u)
                    XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == p.id }), "Rooms missing participant id:\(p.id ?? "-")")
                }
            } else {
                XCTFail()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGetRoom() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            try room.save()
        } catch {
            XCTFail(error.localizedDescription)
        }
        let request = try! Request(method: .get, uri: "/chat/room/\(roomUniqueId)")
        request.headers["Content-Type"] = "application/json"
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        guard let body = response.body.bytes else {
            XCTFail()
            return
        }
        let node = try! JSON(bytes: body)
        let uniqueID = node["uniqueid"]
        guard let id = uniqueID?.string, id == roomUniqueId.lowercased() else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode == 200)
    }
    
    func testGetRoomFailure() {
        let roomUniqueId = UUID().uuidString
        let request = try! Request(method: .get, uri: "/chat/room/\(roomUniqueId)")
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode == 404)
    }
    
    func testAddUserToRoom() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            try room.save()
            var user1 = try User(id: 1)
            try user1.save()
            let request = try! Request(method: .post, uri: "/chat/room/\(roomUniqueId)")
            request.headers["Content-Type"] = "application/json"
            request.body = try user1.makeJSON().makeBody()
            guard let response = try? drop.respond(to: request) else {
                XCTFail()
                return
            }
            guard let body = response.body.bytes else {
                XCTFail()
                return
            }
            let node = try! JSON(bytes: body)
            let uniqueID = node["uniqueid"]
            guard let id = uniqueID?.string, id == roomUniqueId.lowercased() else {
                XCTFail()
                return
            }
            XCTAssertTrue(response.status.statusCode == 200)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testAddUsersToRoom() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            try room.save()
            let request = try! Request(method: .post, uri: "/chat/room/\(roomUniqueId)")
            request.headers["Content-Type"] = "application/json"
            request.body = JSON([
                try user1.makeJSON(),
                try user2.makeJSON(),
                try user3.makeJSON()]).makeBody()
            guard let response = try? drop.respond(to: request) else {
                XCTFail()
                return
            }
            guard let body = response.body.bytes else {
                XCTFail()
                return
            }
            let node = try! JSON(bytes: body)
            let uniqueID = node["uniqueid"]
            guard let id = uniqueID?.string, id == roomUniqueId.lowercased() else {
                XCTFail()
                return
            }
            XCTAssertTrue(response.status.statusCode == 200)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testAddUsersToRoomWithVeryfication() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            try room.save()
            let request = try! Request(method: .post, uri: "/chat/room/\(roomUniqueId)")
            request.headers["Content-Type"] = "application/json"
            request.body = JSON([
                try user1.makeJSON(),
                try user2.makeJSON(),
                try user3.makeJSON()]).makeBody()
            guard let response = try? drop.respond(to: request) else {
                XCTFail()
                return
            }
            guard let body = response.body.bytes else {
                XCTFail()
                return
            }
            let node = try! JSON(bytes: body)
            let uniqueID = node["uniqueid"]
            guard let id = uniqueID?.string, id == roomUniqueId.lowercased() else {
                XCTFail()
                return
            }
            XCTAssertTrue(response.status.statusCode == 200)
            
            let receivers: [User] = try room.participants()
            XCTAssertTrue(receivers.count == 3, "Rooms wrong participants number")
            XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == user1.id }), "Rooms missing participant id:1")
            XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == user2.id }), "Rooms missing participant id:2")
            XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == user3.id }), "Rooms missing participant id:3")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGetRoomParticipant() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            try room.save()
            var user1 = try User(id: 1)
            try user1.save()
            var user2 = try User(id: 2)
            try user2.save()
            var user3 = try User(id: 3)
            try user3.save()
            let _ = try Pivot<User, DMRoom>.getOrCreate(user1, room)
            let _ = try Pivot<User, DMRoom>.getOrCreate(user2, room)
            let _ = try Pivot<User, DMRoom>.getOrCreate(user3, room)
        } catch {
            XCTFail(error.localizedDescription)
        }
        let request = try! Request(method: .get, uri: "/chat/room/\(roomUniqueId)/participant")
        request.headers["Content-Type"] = "application/json"
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        guard let body = response.body.bytes else {
            XCTFail()
            return
        }
        let json = try! JSON(bytes: body)
        guard let array = json.pathIndexableArray else {
            XCTFail()
            return
        }
        do {
            let receivers: [User] = try room.participants()
            for u in array {
                let p = try User(node: u)
                XCTAssertTrue(receivers.contains(where: { user -> Bool in user.id == p.id }), "Rooms missing participant id:\(p.id ?? "-")")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertTrue(response.status.statusCode == 200)
    }
    
    func testGetParticipantRooms() {
        var room1 = DMRoom(uniqueId: UUID().uuidString, name: "FRoom")
        var room2 = DMRoom(uniqueId: UUID().uuidString, name: "SRoom")
        var room3 = DMRoom(uniqueId: UUID().uuidString, name: "TRoom")
        do {
            try room1.save()
            try room2.save()
            try room3.save()
            var user = try User(id: 1)
            try user.save()
            let _ = try Pivot<User, DMRoom>.getOrCreate(user, room1)
            let _ = try Pivot<User, DMRoom>.getOrCreate(user, room2)
            let _ = try Pivot<User, DMRoom>.getOrCreate(user, room3)
        } catch {
            XCTFail(error.localizedDescription)
        }
        let request = try! Request(method: .get, uri: "/chat/participant/1/rooms")
        request.headers["Content-Type"] = "application/json"
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        guard let body = response.body.bytes else {
            XCTFail()
            return
        }
        let json = try! JSON(bytes: body)
        guard let array = json.pathIndexableArray else {
            XCTFail()
            return
        }
        do {
            XCTAssertTrue(array.count == 3, "Rooms wrong number \(array.count)")
            try array.forEach() {
                let room = try DMRoom(node: $0)
                XCTAssertTrue(["FRoom","SRoom","TRoom"].contains(room.name), "Rooms missing")
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertTrue(response.status.statusCode == 200)
    }
    
    func testGetNotFoundRoomHistory() {
        let roomUniqueId = UUID().uuidString
        let request = try! Request(method: .get, uri: "/chat/history/\(roomUniqueId)")
        request.headers["Content-Type"] = "application/json"
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode == 404)
    }
    
    func testGetRoomHistory() {
        let roomUniqueId = UUID().uuidString
        var room = DMRoom(uniqueId: roomUniqueId, name: "Maciek")
        do {
            try room.save()
        } catch {
            XCTFail(error.localizedDescription)
        }
        let request = try! Request(method: .get, uri: "/chat/history/\(roomUniqueId)")
        request.headers["Content-Type"] = "application/json"
        guard let response = try? drop.respond(to: request) else {
            XCTFail()
            return
        }
        XCTAssertTrue(response.status.statusCode == 200)
    }
    
    func testConfiguration() {
        let config = DMDefaultConfiguration()
        XCTAssertNotNil(config)
    }
    
    func testConfigurationInterval() {
        let config = DMDefaultConfiguration()
        XCTAssertTrue(config.pingIterval == 10, "interval is wrong")
    }
    
    func testErrorMessages() {
        XCTAssertTrue(DMFlowControllerError.jsonWrongContent.description == "JSON have wrong context")
        XCTAssertTrue(DMFlowControllerError.unableToReadRoomParameter.description == "unable to read room parameter")
        XCTAssertTrue(DMFlowControllerError.unableToReadMessageTypeParameter.description == "unable to read message type")
        XCTAssertTrue(DMFlowControllerError.unknowMessageType.description == "unknown message type")
        XCTAssertTrue(DMFlowControllerError.unableToReadBodyParameter.description == "unable to ready body parameter")
        XCTAssertTrue(DMFlowControllerError.missingSenderId.description == "missing sender's id")
        XCTAssertTrue(DMFlowControllerError.unableToGetOrCreatePivot.description == "unable to get or create pivot")
    }
}
