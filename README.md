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

```swift
.Package(url:"https://github.com/shial4/VaporDM.git", majorVersion: 0, minor: 1)
```

And then make sure to regenerate your xcode project. You can use `vapor xcode -y` command, if you have the Vapor toolbox installed.

## 🚀 Usage

### 1- Import

It's really easy to get started with the VaporDM library! First you need to import the library, by adding this to the top of your Swift file:
```swift
import VaporDM
```

### 2- Initialize

The easiest way to setup VaporDM is to create object for example in your `main.swift` file. Like this:
```swift
import Vapor
import VaporDM

let drop = Droplet()
let dm = VaporDM(for: drop!, withUser: User.self)
```
VaporDM require your `User` DataBase model to corespond `DMParticipant` protocol
```
extension User: DMParticipant {
    
}
```

## ⭐ Contributing

Be welcome to contribute to this project! :)

## ❓ Questions

You can join the Vapor [slack](http://vapor.team). Or you can create an issue on GitHub.

## ⭐ License

This project was released under the [MIT](license) license.
