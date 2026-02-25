// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SWON

public protocol SWONEncodable {
    func toSWON() throws -> swon_t
}

public protocol SWONDecodable {
    init(fromSWON root: swon_t) throws
}
