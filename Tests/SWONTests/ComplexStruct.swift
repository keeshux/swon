// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SWON

@SWON
struct ComplexStruct: Equatable, Codable {
    // Primitive types
    let intValue: Int
    let doubleValue: Double
    let boolValue: Bool
    let stringValue: String

    // Optional primitives
    let optionalInt: Int?
    let optionalDouble: Double?
    let optionalBool: Bool?
    let optionalString: String?

    // Arrays
    let intArray: [Int]
    let stringArray: [String]
    let optionalDoubleArray: [Double]?

    // Nested arrays
    let nestedIntArray: [[Int]]

    // Dictionaries
    let stringToInt: [String: Int]
    let stringToString: [String: String]
    let optionalStringToBool: [String: Bool]?

    // Dictionaries with array values
    let stringToIntArray: [String: [Int]]

    // Nested dictionaries
    let nestedDictionary: [String: [String: Int]]
    let optionalNestedDictionary: [String: [String: String]]?

    // Mixed combinations
    let arrayOfDictionaries: [[String: Int]]

    // Optional struct reference (self-contained for demonstration)
    let optionalNestedStruct: SubStruct?

    // Optional array of nested structs
    let nestedStructArray: [SubStruct]?

    let stringToSubStruct: [String: SubStruct]
    let optionalStringToSubStruct: [String: SubStruct]?
    let optionalStringToSubStructArray: [String: [SubStruct]]?
}

@SWON
enum Color: String, Codable {
    case red, green, blue
}

@SWON
enum Size: Int, Codable {
    case small, medium, large
}

@SWON
enum Status: String, Codable {
    case active, inactive, pending
}

@SWON
struct SubStruct: Equatable, Codable {
    let favoriteColor: Color
    let optionalSize: Size?
    let statusHistory: [Status]
    let colorToStatus: [String: Status]
    let optionalColorArray: [Color]?
    let assEnum: [AssociatedEnum]?
}

@SWON
enum AssociatedEnum: Equatable, Codable {
    case single
    case singleFlat(String)
    case singleKeyed(i: Int)
    case multipleFlat(Int, Bool)
    case multipleKeyed(d: Double, b: Bool)
    case multipleMixed(d: Double, Bool, foo: SubStruct)
}
