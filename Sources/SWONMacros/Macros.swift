// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftDiagnostics
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
        let typeName = type.description
        // context.diagnose(
        //     Diagnostic(
        //         node: Syntax(node),
        //         message: SWONMessage(message: "FQN = \(typeName)")
        //     )
        // )
        let ext = try ExtensionDeclSyntax(
            "extension \(raw: typeName): SWONDecodable, SWONEncodable {}"
        )
        return [ext]
    }
}
