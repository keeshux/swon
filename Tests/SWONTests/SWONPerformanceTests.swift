// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import XCTest

final class SWONPerformanceTests: XCTestCase {
    let json = try! jsonString(fromFileNamed: "populated")
    let cycles = 1000

    func testSWONPerformance() throws {
        measure {
            for _ in 0..<cycles {
                _ = try! ComplexStruct.withSWON(json)
            }
        }
    }

    func testFoundationPerformance() {
        measure {
            for _ in 0..<cycles {
                _ = try! ComplexStruct.withFoundation(json)
            }
        }
    }
}
