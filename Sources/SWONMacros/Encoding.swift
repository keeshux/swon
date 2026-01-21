// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SWONEncodeMacro: MemberMacro {
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
//                    message: SWONMessage(message: "Raw type of enum \(enumType) is \(rawType)")
//                )
//            )
            switch rawType {
            case "String":
                assignments.append("""
                    var item = swon_t()
                    guard rawValue.withCString({ swon_create_string(&item, $0) }) else {
                        throw SWONError.invalid("\(enumType)(String)")
                    }
                    return item
                    """)
            case "Int":
                assignments.append("""
                    var item = swon_t()
                    guard swon_create_number(&item, Double(rawValue)) else {
                        throw SWONError.invalid("\(enumType)(Int)")
                    }
                    return item
                    """)
            default:
                fatalError("Unsupported raw type '\(rawType)'")
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
                let stmts = mapItem(
                    to: type.decodedType(context: context),
                    varName: field,
                    parentName: "root",
                    nesting: 0,
                    category: type.isOptional ? .optional : .none
                )
                assignments.append(contentsOf: stmts)
            }
            assignments.append("return root")
        }
//        context.diagnose(
//            Diagnostic(
//                node: Syntax(node),
//                message: SWONMessage(message: "Assignments: \(assignments)")
//            )
//        )
        return [
            DeclSyntax(stringLiteral: """
                func toSWON() throws -> swon_t {
                    var root = swon_t()
                    guard swon_create_object(&root) else {
                        throw SWONError.invalid("Unable to create root")
                    }
                    do {
                        \(assignments.joined(separator: "\n"))
                    } catch {
                        swon_free(&root)
                        throw error
                    }
                }
                """),
            DeclSyntax(stringLiteral: """
                func toJSON() throws -> String {
                    var item = try toSWON()
                    defer { swon_free(&item) }
                    guard let cjson = swon_encode(item) else {
                        throw SWONError.invalid("Unable to encode self")
                    }
                    let json = String(cString: cjson)
                    swon_free_string(cjson)
                    return json
                }
                """)
        ]
    }
}

private extension SWONEncodeMacro {
    static func mapItem(
        to type: DecodedType,
        varName: String,
        parentName: String,
        nesting: Int,
        category: TypeCategory
    ) -> [String] {
        var stmts: [String] = []
        if category == .optional {
            stmts.append("if let \(varName) {")
        }
        switch type {
        case .scalar:
            stmts.append(
                contentsOf: type.statements(forName: "\(varName)JSON", element: varName, pair: false)
            )
            stmts.append("""
                guard swon_object_add_item(&\(parentName), "\(varName)", \(varName)JSON) else {
                    swon_free(&\(varName)JSON)
                    throw SWONError.invalid("Unable to add scalar to object in \(parentName) (\(varName)JSON)")
                }
                """)
        case .optional(let wrappedType):
            return mapItem(
                to: wrappedType,
                varName: varName,
                parentName: parentName,
                nesting: nesting,
                category: .optional
            )
        case .array(let elementType):
            let elementName = "element\(nesting)"
            let itemName = "element\(nesting)JSON"
            let itemExpr: [String] = {
                switch elementType {
                case .optional:
                    fatalError("Collection of optionals is not supported")
                case .array:
                    return mapItem(
                        to: elementType,
                        varName: elementName,
                        parentName: parentName,
                        nesting: nesting + 1,
                        category: .array
                    )
                case .dictionary:
                    return mapItem(
                        to: elementType,
                        varName: elementName,
                        parentName: parentName,
                        nesting: nesting + 1,
                        category: .array
                    )
                case .scalar:
                    return elementType.statements(
                        forName: itemName,
                        element: elementName,
                        pair: false
                    )
                }
            }()
            stmts.append("""
                var \(varName)JSON = swon_t()
                guard swon_create_array(&\(varName)JSON) else {
                    throw SWONError.invalid("Unable to create array in \(parentName) (\(varName)JSON)")
                }
                for element\(nesting) in \(varName)\(category == .dictionary ? ".value" : "") {
                    do {
                        \(itemExpr.joined(separator: "\n"))
                        guard swon_array_add_item(&\(varName)JSON, \(itemName)) else {
                            swon_free(&\(itemName))
                            throw SWONError.invalid("Unable to add item to \(varName)JSON")
                        }
                    } catch {
                        swon_free(&\(varName)JSON)
                        throw error
                    }
                }
                """)
            if !category.isCollection {
                stmts.append("""
                    guard swon_object_add_item(&\(parentName), "\(varName)", \(varName)JSON) else {
                        swon_free(&\(varName)JSON)
                        throw SWONError.invalid("Unable to set array in \(parentName)[\(varName)] (\(varName)JSON)")
                    }
                    """)
            }
        case .dictionary(let key, let valueType):
            guard case .scalar(let keyTypeName) = key, keyTypeName == "String" else {
                fatalError("Expected string keys")
            }
            let elementName = "element\(nesting)"
            let itemName = "element\(nesting)JSON"
            let itemExpr: [String] = {
                switch valueType {
                case .optional:
                    fatalError("Collection of optionals is not supported")
                case .array:
                    return mapItem(
                        to: valueType,
                        varName: elementName,
                        parentName: parentName,
                        nesting: nesting + 1,
                        category: .dictionary
                    )
                case .dictionary:
                    return mapItem(
                        to: valueType,
                        varName: elementName,
                        parentName: parentName,
                        nesting: nesting + 1,
                        category: .dictionary
                    )
                case .scalar:
                    return valueType.statements(
                        forName: itemName,
                        element: elementName,
                        pair: true
                    )
                }
            }()
            stmts.append("""
                var \(varName)JSON = swon_t()
                guard swon_create_object(&\(varName)JSON) else {
                    throw SWONError.invalid("Unable to create object in \(parentName)")
                }
                for element\(nesting) in \(varName)\(category == .dictionary ? ".value" : "") {
                    \(itemExpr.joined(separator: "\n"))
                    do {
                        guard swon_object_add_item(&\(varName)JSON, element\(nesting).key, \(itemName)) else {
                            swon_free(&\(itemName))
                            throw SWONError.invalid("Unable to set item in \(varName)JSON[\\(element\(nesting).key)]")
                        }
                    } catch {
                        swon_free(&\(varName)JSON)
                        throw error
                    }
                }
                """)
            if !category.isCollection {
                stmts.append("""
                    guard swon_object_add_item(&\(parentName), \"\(varName)\", \(varName)JSON) else {
                        swon_free(&\(varName)JSON)
                        throw SWONError.invalid("Unable to set dictionary in \(parentName)[\(varName)] (\(varName)JSON)")
                    }
                    """)
            }
        }
        if category == .optional {
            stmts.append("}")
        }
        return stmts
    }
}

private extension DecodedType {
    func statements(forName name: String, element: String, pair: Bool) -> [String] {
        var stmts: [String] = []
        let suffix = pair ? ".value" : ""
        var isScalar = true
        stmts.append("var \(name) = swon_t()")
        switch description {
        case "Bool":
            stmts.append("guard swon_create_bool(&\(name), \(element)\(suffix)) else {")
        case "Int":
            stmts.append("guard swon_create_number(&\(name), Double(\(element)\(suffix))) else {")
        case "Double":
            stmts.append("guard swon_create_number(&\(name), \(element)\(suffix)) else {")
        case "String":
            stmts.append("guard swon_create_string(&\(name), \(element)\(suffix)) else {")
        default:
            isScalar = false
            stmts.append("\(name) = try \(element)\(suffix).toSWON()")
        }
        if isScalar {
            stmts.append("throw SWONError.invalid(\"Unable to create item (\(name))\")")
            stmts.append("}")
        }
        return stmts
    }
}

private enum TypeCategory {
    case none
    case optional
    case array
    case dictionary

    var isCollection: Bool {
        switch self {
        case .array, .dictionary:
            return true
        default:
            return false
        }
    }
}
