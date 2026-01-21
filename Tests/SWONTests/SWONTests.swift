// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import Foundation
@testable import SWON
import Testing

struct SWONTests {
    @Test(arguments: ["populated", "minimal", "partial"])
    func decodingParity(filename: String) throws {
        let json = try jsonString(fromFileNamed: filename)
        let parsed = try ComplexStruct.withSWON(json)
        let foundationParsed = try ComplexStruct.withFoundation(json)
        #expect(parsed == foundationParsed)
    }

    @Test
    func encodingEnums() throws {
        #expect(try Size.medium.toJSON() == "1")
        #expect(try Status.inactive.toJSON() == "\"inactive\"")
    }

    @Test
    func encodingStruct() throws {
        @SWON
        struct LocalStruct {
            let favoriteColor: String
            let optionalSize: Int?
            let statusHistory: [String]
            let colorToStatus: [String: String]
            let another: AnotherStruct?
            let nestedStrings: [[String]]
            let nestedColors: [[Color]]
        }
        @SWON
        struct AnotherStruct {
            let one: Int
            let two: Double
        }
        let sut = try LocalStruct(fromJSON: """
{
    "favoriteColor": "green",
    "optionalSize": 1,
    "statusHistory": ["inactive", "pending"],
    "colorToStatus": {"green": "inactive"},
    "optionalColorArray": null,
    "another": {
        "one": 1,
        "two": 2.0
    },
    "nestedStrings": [
        ["one", "two"],
        ["four", "five", "six"]
    ],
    "nestedColors": [
        ["green", "blue"],
        ["red", "red", "green"]
    ]
}
""")
        print(try sut.toJSON())
    }

    @Test(arguments: ["minimal", "partial", "populated"])
    func encodingReversibility(filename: String) throws {
        let json = try jsonString(fromFileNamed: filename)
        let parsed = try ComplexStruct.withSWON(json)
        let encoded = try parsed.toJSON()
        print(encoded)
//        #expect(encoded == json)
        let parsed2 = try ComplexStruct.withSWON(encoded)
        #expect(parsed == parsed2)
    }
}

func jsonString(fromFileNamed name: String) throws -> String {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
        fatalError()
    }
    return try String(contentsOf: url, encoding: .utf8)
}

extension ComplexStruct {
    static func withSWON(_ json: String) throws -> Self {
        try ComplexStruct(fromJSON: json)
    }

    static func withFoundation(_ json: String) throws -> Self {
        let jsonData = try #require(json.data(using: .utf8))
        return try JSONDecoder().decode(ComplexStruct.self, from: jsonData)
    }
}
