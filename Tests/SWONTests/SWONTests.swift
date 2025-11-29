// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import Foundation
@testable import SWON
import Testing

struct SWONTests {
    @Test(arguments: ["populated", "minimal", "partial"])
    func featureParity(filename: String) throws {
        let json = try jsonString(fromFileNamed: filename)
        let parsed = try ComplexStruct.withSWON(json)
        let foundationParsed = try ComplexStruct.withFoundation(json)
        #expect(parsed == foundationParsed)
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
