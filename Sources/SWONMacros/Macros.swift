// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct SWONMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SWONCompoundMacro.self
    ]
}

public struct SWONCompoundMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        var result: [DeclSyntax] = []
        result += try SWONDecodeMacro.expansion(
            of: node,
            providingMembersOf: declaration,
            conformingTo: protocols,
            in: context
        )
        result += try SWONEncodeMacro.expansion(
            of: node,
            providingMembersOf: declaration,
            conformingTo: protocols,
            in: context
        )
        return result
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Extract the type name (struct/class/enum identifier)
        guard let named = declaration.asProtocol(NamedDeclSyntax.self) else {
            return []
        }
        let typeName = named.name.text

        // Optional: avoid duplicate conformances if already declared
        let alreadyConforms: Set<String> =
        declaration.inheritanceClause?
            .inheritedTypes
            .compactMap { $0.type.as(IdentifierTypeSyntax.self)?.name.text }
            .reduce(into: Set<String>()) { $0.insert($1) }
        ?? []
        let needsEncodable = !alreadyConforms.contains("SWONEncodable")
        let needsDecodable = !alreadyConforms.contains("SWONDecodable")
        guard needsEncodable || needsDecodable else {
            return []
        }

        // Build the conformance list dynamically
        var conformances: [String] = []
        if needsEncodable { conformances.append("SWONEncodable") }
        if needsDecodable { conformances.append("SWONDecodable") }
        let conformanceList = conformances.joined(separator: ", ")
        let ext = try ExtensionDeclSyntax(
            "extension \(raw: typeName): \(raw: conformanceList) {}"
        )
        return [ext]
    }
}
