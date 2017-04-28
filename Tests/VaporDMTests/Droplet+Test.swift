//
//  Droplet+Test.swift
//  Cosma
//
//  Created by Shial on 16/02/2017.
//
//

@testable import Vapor
@testable import HTTP
@testable import VaporPostgreSQL

extension Droplet {
    class func makeTestDroplet() throws -> Droplet {
        let drop = Droplet(arguments: ["dummy/path/", "prepare"])
        let postgreSQLConfig: Config = Config(["postgresql" : ["host": "127.0.0.1",
                                                               "user": "default",
                                                               "password": "",
                                                               "database": "test",
                                                               "port": 5432]])
        try drop.addProvider(VaporPostgreSQL.Provider(config: postgreSQLConfig).self)
        drop.preparations += [User.self]
        return drop
    }
    
    func revertDatabase() throws {
        try preparations.forEach {
            if let database = database {
                try $0.revert(database)
                try $0.prepare(database)
            }
        }
    }
    
    func revertAndPrepareDatabase() throws {
        try preparations.forEach {
            if let database = database {
                try $0.revert(database)
                try $0.prepare(database)
            }
        }
    }
}
