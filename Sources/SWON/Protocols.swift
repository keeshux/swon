// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

public protocol SWONEncodable {
    func toSWON() throws -> swon_t
}

public protocol SWONDecodable {
    init(fromSWON root: swon_t) throws
}
