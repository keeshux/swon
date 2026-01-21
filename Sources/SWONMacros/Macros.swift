// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct SWONMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SWONMacro.self,
        SWONEncodeMacro.self,
        SWONDecodeMacro.self
    ]
}

public struct SWONMacro: MemberMacro {
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
}
