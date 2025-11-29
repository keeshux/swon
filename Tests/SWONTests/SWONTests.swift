// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import Foundation
@testable import SWON
import Testing

struct SWONTests {
    private func json(named name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            fatalError()
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test(arguments: ["populated", "minimal", "partial"])
    func populated(filename: String) throws {
        let json = try json(named: filename)
        let parsed = try ComplexStruct(fromJSON: json)
        print(parsed)
        let jsonData = try #require(json.data(using: .utf8))
        let foundationParsed = try JSONDecoder().decode(ComplexStruct.self, from: jsonData)
        #expect(parsed == foundationParsed)
    }
}
