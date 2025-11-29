// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct SWONMacro: MemberMacro {
    public static func expansion(
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
                variable.bindings.first?.initializer == nil // ignore default-init vars
            }

        var assignments: [String] = []

        // Parse enum from raw value
        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            guard let inheritance = enumDecl.inheritanceClause,
                  let inheritedType = inheritance.inheritedTypes.first else {
                fatalError("Enumeration must inherit a raw type")
            }
            let enumType = enumDecl.name.text
            let rawType = inheritedType.type.description
//            context.diagnose(
//                Diagnostic(
//                    node: Syntax(node),
//                    message: SWONMessage(message: "Raw type of enum \(enumDecl.name.text) is \(rawType)")
//                )
//            )
            switch rawType {
            case "String":
                assignments.append("""
                    var str: UnsafePointer<CChar>!
                    try swon_get_string(root, &str).check("\(enumType)")
                    let rawValue = String(cString: str)
                    guard let value = \(enumType)(rawValue: rawValue) else {
                        throw SWONError.invalid("\(enumType).\\(rawValue)")
                    }
                    self = value
                    """)
            case "Int":
                assignments.append("""
                    var num: Int32 = 0
                    try swon_get_integer(root, &num).check("\(enumType)")
                    guard let value = \(enumType)(rawValue: Int(num)) else {
                        throw SWONError.invalid("\(enumType).\\(num)")
                    }
                    self = value
                    """)
            default:
//                fatalError("Unsupported raw type '\(rawType)'")
                break
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
                    let itemResult = swon_get_object(root, "\(field)", &item)
                    try itemResult.check("\(field)")
                    \(mapItem(to: type.decodedType(context: context), fieldName: field, varName: "item", nesting: 0, isOptional: type.isOptional))
                }()
            """)
            }
        }
        return [
            DeclSyntax(stringLiteral: """
                init(fromSWON root: swon_t) throws {
                    \(assignments.joined(separator: "\n"))
                }
                """),
            DeclSyntax(stringLiteral: """
                init(fromJSON json: String) throws {
                    var root = swon_t()
                    guard swon_create(json, &root) == SWONResultValid else {
                        let message = String(cString: swon_error_ptr())
                        throw SWONError.invalid("At \\(message)")
                    }
                    defer {
                        swon_free(root)
                    }
                    try self.init(fromSWON: root)
                }
                """)
        ]
    }
}

private extension SWONMacro {
    static func mapItem(to type: DecodedType, fieldName: String, varName: String, nesting: Int, isOptional: Bool) -> String {
        let typeExpr: String
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
            typeExpr = {
                switch typeName {
                case "String":
                    return """
                        var str: UnsafePointer<CChar>!
                        let result = swon_get_string(\(varName), &str)
                        \(checkExpr)
                        return String(cString: str)
                        """
                case "Int":
                    return """
                        var num: Int32 = 0
                        let result = swon_get_integer(\(varName), &num)
                        \(checkExpr)
                        return Int(num)
                        """
                case "Double":
                    return """
                        var num: Double = 0
                        let result = swon_get_number(\(varName), &num)
                        \(checkExpr)
                        return num
                        """
                case "Bool":
                    return """
                        var bool = false
                        let result = swon_get_bool(\(varName), &bool)
                        \(checkExpr)
                        return bool
                        """
                default:
                    return "return try \(typeName)(fromSWON: \(varName))"
                }
            }()
        case .optional(let wrappedType):
            typeExpr = mapItem(to: wrappedType, fieldName: fieldName, varName: varName, nesting: nesting, isOptional: true)
        case .array(let elementType):
            typeExpr = """
                var list: [\(elementType.description)] = []
                let size = swon_get_array_size(\(varName))
                for i in 0..<size {
                    var arrayElement\(nesting) = swon_t()
                    switch swon_get_array_item(\(varName), Int32(i), &arrayElement\(nesting)) {
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
            typeExpr = """
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
        return """
            \(typeExpr)
            """
    }
}

// MARK: - Helpers

indirect enum DecodedType {
    case scalar(_ name: String)
    case array(_ element: DecodedType)
    case dictionary(key: DecodedType, value: DecodedType)
    case optional(DecodedType)
}

extension DecodedType {
    var description: String {
        switch self {
        case .scalar(let name):
            return name
        case .array(let element):
            return "[\(element.description)]"
        case .dictionary(let key, let value):
            return "[\(key.description): \(value.description)]"
        case .optional(let wrapped):
            switch wrapped {
            case .scalar(let name):
                return "\(name)?"
            default:
                return "\(wrapped.description)?"
            }
        }
    }
}

extension TypeSyntax {
    func decodedType(context: some MacroExpansionContext) -> DecodedType {
        switch `as`(TypeSyntaxEnum.self) {
        case .identifierType(let id):
            return .scalar(id.name.text)
        case .memberType(let m):
            return .scalar(m.description)
        case .arrayType(let arr):
            return .array(arr.element.decodedType(context: context))
        case .dictionaryType(let dict):
            return .dictionary(
                key: dict.key.decodedType(context: context),
                value: dict.value.decodedType(context: context)
            )
        case .optionalType(let opt):
            return .optional(opt.wrappedType.decodedType(context: context))
        default:
            return .scalar(description)
        }
    }

    var isOptional: Bool {
        guard case .optionalType = `as`(TypeSyntaxEnum.self) else {
            return false
        }
        return true
    }
}

struct SWONMessage: DiagnosticMessage {
    let severity: DiagnosticSeverity = .note
    let message: String
    var diagnosticID: MessageID {
        MessageID(domain: "SWONMessage", id: "debug")
    }
}
