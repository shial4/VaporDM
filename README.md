# VaporDM

[![Language](https://img.shields.io/badge/Swift-3.1-brightgreen.svg)](http://swift.org)
![Vapor](https://img.shields.io/badge/Vapor-1.0-green.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/shial4/VaporDM/master/license)
[![Build Status](https://travis-ci.org/shial4/VaporDM.svg?branch=master)](https://travis-ci.org/shial4/VaporDM)
[![codecov](https://codecov.io/gh/shial4/VaporDM/branch/master/graph/badge.svg)](https://codecov.io/gh/shial4/VaporDM)

VaporDM is a simple, yet elegant, Swift library that allows you to integrate chat system into your Vapor project.

## 🔧 Installation

A quick guide, step by step, about how to use this library.

### 1- Add VaporDM to your project

Add the following dependency to your `Package.swift` file:

For Pre-release version
```swift
.Package(url: "https://github.com/shial4/VaporDM.git", Version(0, 1, 0, prereleaseIdentifiers: ["alpha", "2"]))
```

For official release version (coming soon)
```swift
.Package(url:"https://github.com/shial4/VaporDM.git", majorVersion: 0, minor: 1)
```

And then make sure to regenerate your xcode project. You can use `vapor xcode -y` command, if you have the Vapor toolbox installed.

## 🚀 Usage

### 1 Import

It's really easy to get started with the VaporDM library! First you need to import the library, by adding this to the top of your Swift file:
```swift
import VaporDM
```

### 2 Initialize

The easiest way to setup VaporDM is to create object for example in your `main.swift` file. Like this:
```swift
import Vapor
import VaporDM

let drop = Droplet()
let dm = VaporDM<User>(for: drop!)
```
VaporDM require your `User` DataBase model to corespond `DMParticipant` protocol
```
extension User: DMParticipant {}
```

### 3 Message format
VaporDM support message `Type` such as:
```
connected = "C"
disconnected = "D"
messageText = "M"
beginTyping = "B"
endTyping = "E"
readMessage = "R"
```
To send text message we will use type `M` and address it to `DMRoom`. Vapor Direct Message send messages to room which are dispatch to room participants. Sending Message to non existing room will create that room.
`DMRoom` repreents group of users between messages are sent.
Text message example:
```
{  
   "room":"a5b7c179-ff9f-41f7-a2a7-9c127b8bf1ac",
   "type":"M",
   "body":"This is a text message"
}
```

To work with `VaporDM` you will need to know how to use endpoints for creating message rooms adding/removing users and geting list of room participants.

#### 1 Create message room
method: `POST` uri: `/chat/room/${ROOM_ID}`
To create room we need send `JSON` with `DMRoom` object inside. Room require minimum `uniqueid` and `name` to be in this json.
```
{  
   "uniqueid":"a5b7c179-ff9f-41f7-a2a7-9c127b8bf1ac",
   "name":"Room Name"
}
```

#### 2 Get room
method: `GET` uri: `/chat/room/${ROOM_ID}`

#### 3 Add User/Users to room
method: `POST` uri: `/chat/room/${ROOM_ID}`
To add users simple send `JSON` with single user or `JSON` with array of users.

#### 4 Get room participant
method: `GET` uri: `/chat/room/${ROOM_ID}/participant`

### 2 Connection
To connect under `WebSocket` simple use this url `"ws://${Your_host_and_additional_path}/chat/service/${ROOM_ID}"`

## ⭐ Contributing

Be welcome to contribute to this project! :)

## ❓ Questions

You can join the Vapor [slack](http://vapor.team). Or you can create an issue on GitHub.

## ⭐ License

This project was released under the [MIT](license) license.
