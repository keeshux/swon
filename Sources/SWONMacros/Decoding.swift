// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct SWONDecodeMacro: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(EnumDeclSyntax.self) else {
            fatalError("@SWON can only be applied to a struct or enum")
        }
        let properties = declaration
            .memberBlock
            .members
            .compactMap {
                $0.decl.as(VariableDeclSyntax.self)
            }
            .filter { variable in
                variable.bindings.first?.initializer == nil // Ignore default-init vars
            }

        var assignments: [String] = []

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            let enumType = enumDecl.name.text

            // Enum with associated values
            if enumDecl.hasAssociatedValues {
                let cases = enumDecl.cases
//                context.diagnose(
//                    Diagnostic(
//                        node: Syntax(node),
//                        message: SWONMessage(message: "Associated cases of enum \(enumType): \(cases.map(\.description))")
//                    )
//                )
                // FIXME: ###, Ensure root is an actual object
                assignments.append("""
                    let child = swon_get_map_first(root)
                    guard let key = swon_get_map_key(child) else {
                        throw SWONError.invalid("Unable to find enum dictionary")
                    }
                    """)

                assignments.append("switch String(cString: key) {")
                cases.forEach {
                    $0.elements.forEach { el in
                        assignments.append("case \"\(el.name)\":")
                        guard let parms = el.parameterClause?.parameters, !parms.isEmpty else {
                            assignments.append("self = .\(el.name)")
                            return
                        }
                        var parmAssignments: [String] = []
                        parms.enumerated().forEach { i, p in
                            let name: String
                            var type = p.type.decodedType(context: context)
                            var isOptional = false
                            if case .optional(let decodedType) = type {
                                type = decodedType
                                isOptional = true
                            }
                            if let firstName = p.firstName {
                                name = firstName.description
                                parmAssignments.append("\(name): \(name)")
                            } else {
                                name = "_\(i)"
                                parmAssignments.append(name)
                            }
                            assignments.append("""
                                let \(name): \(type.description)\(isOptional ? "?" : "") = try {
                                    var dict = swon_t()
                                    let dictResult = swon_get_object(&dict, child, "\(name)")
                                """)
                            if isOptional {
                                assignments.append("""
                                    guard dictResult != SWONResultNull else { return nil }
                                    """)
                            }
                            assignments.append("""
                                    try dictResult.check("\(name) in \(el.name)")
                                    \(mapItem(to: type, fieldName: "\(name) in \(el.name)", varName: "dict", nesting: 0, isOptional: isOptional))
                                }()
                                """)
                        }
                        let parmAssignmentList = parmAssignments.joined(separator: ",")
                        assignments.append("self = .\(el.name)(\(parmAssignmentList))")
                    }
                }
                assignments.append("default: throw SWONError.invalid(\"Unknown enum case '\\(key)'\")")
                assignments.append("}")
            }
            // Enum with raw value
            else if let inheritedType = enumDecl.inheritanceClause?.inheritedTypes.first {
                let rawType = inheritedType.type.description.trimmingTrailingWhitespaces
//                context.diagnose(
//                    Diagnostic(
//                        node: Syntax(node),
//                        message: SWONMessage(message: "Raw type of enum \(enumType) is \(rawType)")
//                    )
//                )
                switch rawType {
                case "String":
                    assignments.append("""
                    var str: UnsafePointer<CChar>!
                    try swon_get_string(&str, root).check("\(enumType)")
                    let rawValue = String(cString: str)
                    guard let value = \(enumType)(rawValue: rawValue) else {
                        throw SWONError.invalid("\(enumType).\\(rawValue)")
                    }
                    self = value
                    """)
                case "Int", "UInt":
                    assignments.append("""
                    var num: Int32 = 0
                    try swon_get_integer(&num, root).check("\(enumType)")
                    guard let value = \(enumType)(rawValue: \(rawType)(num)) else {
                        throw SWONError.invalid("\(enumType).\\(num)")
                    }
                    self = value
                    """)
                default:
                    fatalError("Unsupported raw type '\(rawType)'")
                }
            }
        } else {
            // Parse struct fields
            for prop in properties {
                guard let field = prop.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                    continue
                }
                guard let type = prop.bindings.first?.typeAnnotation?.type else {
                    continue
                }
//                context.diagnose(
//                    Diagnostic(
//                        node: Syntax(node),
//                        message: SWONMessage(message: "Assigning \(field) of type \(type)")
//                    )
//                )
                assignments.append("""
                \(field) = try\(type.isOptional ? "?" : "") {
                    var item = swon_t()
                    let itemResult = swon_get_object(&item, root, "\(field)")
                    try itemResult.check("\(field)")
                    \(mapItem(to: type.decodedType(context: context), fieldName: field, varName: "item", nesting: 0, isOptional: type.isOptional))
                }()
            """)
            }
        }
        return [
            DeclSyntax(stringLiteral: """
                public init(fromSWON root: swon_t) throws {
                    \(assignments.joined(separator: "\n"))
                }
                """),
            DeclSyntax(stringLiteral: """
                public init(fromJSON json: String) throws {
                    var root = swon_t()
                    defer { swon_free(&root) }
                    guard swon_parse(&root, json) == SWONResultValid else {
                        let message = String(cString: swon_parse_error_ptr())
                        throw SWONError.invalid("At \\(message)")
                    }
                    try self.init(fromSWON: root)
                }
                """)
        ]
    }
}

private extension SWONDecodeMacro {
    static func mapItem(to type: DecodedType, fieldName: String, varName: String, nesting: Int, isOptional: Bool) -> String {
        switch type {
        case .scalar(let typeName):
            let checkExpr = """
                switch result {
                case SWONResultValid:
                    break
                case SWONResultNull:
                    \(isOptional ? "return nil" : "throw SWONError.required(\"\(fieldName)\")")
                default:
                    throw SWONError.invalid("\(fieldName)")
                }
                """
            switch typeName {
            case "String":
                return """
                    var str: UnsafePointer<CChar>!
                    let result = swon_get_string(&str, \(varName))
                    \(checkExpr)
                    return String(cString: str)
                    """
            case "Int":
                return """
                    var num: Int32 = 0
                    let result = swon_get_integer(&num, \(varName))
                    \(checkExpr)
                    return Int(num)
                    """
            case "Double":
                return """
                    var num: Double = 0
                    let result = swon_get_number(&num, \(varName))
                    \(checkExpr)
                    return num
                    """
            case "Bool":
                return """
                    var bool = false
                    let result = swon_get_bool(&bool, \(varName))
                    \(checkExpr)
                    return bool
                    """
            default:
                return "return try \(typeName)(fromSWON: \(varName))"
            }
        case .optional(let wrappedType):
            return mapItem(to: wrappedType, fieldName: fieldName, varName: varName, nesting: nesting, isOptional: true)
        case .array(let elementType):
            return """
                var list: [\(elementType.description)] = []
                let size = swon_get_array_size(\(varName))
                for i in 0..<size {
                    var arrayElement\(nesting) = swon_t()
                    switch swon_get_array_item(&arrayElement\(nesting), \(varName), Int32(i)) {
                    case SWONResultValid:
                        break
                    default:
                        continue
                    }
                    let arrayElementValue\(nesting) = try {
                        \(mapItem(to: elementType, fieldName: "\(fieldName)[]", varName: "arrayElement\(nesting)", nesting: nesting + 1, isOptional: false))
                    }()
                    list.append(arrayElementValue\(nesting))
                }
                return list
                """
        case .dictionary(let key, let valueType):
            guard case .scalar(let keyTypeName) = key, keyTypeName == "String" else {
                fatalError("Expected string keys")
            }
            return """
                var map: [\(keyTypeName): \(valueType.description)] = [:]
                var mapElement\(nesting) = swon_get_map_first(\(varName))
                while swon_get_map_exists(mapElement\(nesting)) {
                    if let key = swon_get_map_key(mapElement\(nesting)) {
                        let mapElementValue\(nesting) = try {
                            \(mapItem(to: valueType, fieldName: "\(fieldName)[]", varName: "mapElement\(nesting)", nesting: nesting + 1, isOptional: false))
                        }()
                        map[String(cString: key)] = mapElementValue\(nesting)
                    }
                    mapElement\(nesting) = swon_get_map_next(mapElement\(nesting))
                }
                return map
                """
        }
    }
}
