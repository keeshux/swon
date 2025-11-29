// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SWONMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SWONMacro.self,
    ]
}
