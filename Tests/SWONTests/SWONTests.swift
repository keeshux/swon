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
    func encodingAssociatedEnums() throws {
        @SWON
        struct LocalContainer {
            let enums: [AssociatedEnum]
            init(enums: [AssociatedEnum]) {
                self.enums = enums
            }
        }
        let sub = try SubStruct(fromJSON: """
        {
            "favoriteColor": "red",
            "optionalSize": 0,
            "statusHistory": ["active"],
            "colorToStatus": {"red": "active"},
            "optionalColorArray": ["blue"]
        }
        """)
        let sut = LocalContainer(enums: [
            .single,
            .singleFlat("flat"),
            .singleKeyed(i: 100),
            .multipleFlat(50, true),
            .multipleKeyed(d: 70.0, b: false),
            .multipleMixed(d: 600.0, nil, foo: sub)
        ])
        let json = try sut.toJSON()
        print(json)
    }

    @Test
    func decodingAssociatedEnums() throws {
        let json = """
{"enums":[{"single":{}},{"singleFlat":{"_0":"flat"}},{"singleKeyed":{"i":100}},{"multipleFlat":{"_0":50,"_1":true}},{"multipleKeyed":{"d":70,"b":false}},{"multipleMixed":{"d":600,"foo":{"favoriteColor": "blue", "statusHistory": [], "colorToStatus": {}}}}]}
"""
        let sut = try LocalContainer(fromJSON: json)
        print(json)
        print(sut)
    }

    @Test
    func encodingStruct() throws {
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

@SWON
struct LocalContainer {
    let enums: [AssociatedEnum]
    init(enums: [AssociatedEnum]) {
        self.enums = enums
    }
}

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
