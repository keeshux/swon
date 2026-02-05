// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: MIT

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

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

extension EnumDeclSyntax {
    var cases: [EnumCaseDeclSyntax] {
        memberBlock.members
            .compactMap { member in
                member.decl.as(EnumCaseDeclSyntax.self)
            }
    }

    var hasAssociatedValues: Bool {
        cases.contains { caseDecl in
            caseDecl.elements.contains { element in
                element.parameterClause != nil
            }
        }
    }
}

struct SWONMessage: DiagnosticMessage {
    let severity: DiagnosticSeverity = .note
    let message: String
    var diagnosticID: MessageID {
        MessageID(domain: "SWONMessage", id: "debug")
    }
}

extension String {
    var trimmingTrailingWhitespaces: String {
        var copy = self
        while copy.last == " " {
            copy.removeLast()
        }
        return copy
    }
}
