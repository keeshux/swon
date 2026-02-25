// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

@_exported import SWON_C

@attached(member, names:
            named(init(fromSWON:)),
            named(init(fromJSON:)),
            named(toSWON),
            named(toJSON)
)
@attached(extension, conformances: SWONEncodable, SWONDecodable)
public macro SWON() = #externalMacro(
    module: "SWONMacros",
    type: "SWONCompoundMacro"
)

public enum SWONError: Error {
    case required(String)
    case invalid(String)
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
