// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

@_exported import SWON_C

@attached(member, names: named(init(fromSWON:)), named(init(fromJSON:)))
public macro SWON() = #externalMacro(
    module: "SWONMacros",
    type: "SWONMacro"
)

public enum SWONError: Error {
    case required(String)
    case invalid(String)
    case message(String)
}

extension swon_result {
    public func check(_ field: String) throws {
        switch self {
        case SWONResultNull:
            throw SWONError.required(field)
        case SWONResultInvalid:
            throw SWONError.invalid(field)
        default:
            break
        }
    }
}
