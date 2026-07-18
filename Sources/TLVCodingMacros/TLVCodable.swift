//
//  TLVCodable.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@TLVCodable` macro
///
/// Adds `TLVCodable` protocol conformance with a generated `CodingKeys` enum,
/// `init?(tlvData:)` initializer and `tlvData` computed property.
public struct TLVCodableMacro: MemberMacro, ExtensionMacro {

    // Add protocol conformance via extension
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let extensionDecl = ExtensionDeclSyntax(
            leadingTrivia: nil,
            attributes: [],
            modifiers: [],
            extensionKeyword: .keyword(.extension),
            extendedType: TypeSyntax(type),
            inheritanceClause: InheritanceClauseSyntax(
                colon: .colonToken(trailingTrivia: .space),
                inheritedTypes: InheritedTypeListSyntax {
                    InheritedTypeSyntax(
                        type: TypeSyntax(stringLiteral: "TLVCoding.TLVCodable")
                    )
                }
            ),
            genericWhereClause: nil,
            memberBlock: MemberBlockSyntax(members: [])
        )
        return [extensionDecl]
    }

    // Add members
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw MacroError.invalidType
        }
        let properties = try storedProperties(of: declaration)
        guard properties.isEmpty == false else {
            throw MacroError.noStoredProperties
        }
        var declarations = [DeclSyntax]()
        if hasCodingKeys(declaration) == false {
            declarations.append(codingKeysDeclarationSyntax(for: properties, of: declaration))
        }
        declarations.append(initDeclarationSyntax(for: properties, of: declaration))
        declarations.append(tlvDataDeclarationSyntax(for: properties, of: declaration))
        return declarations
    }
}

extension TLVCodableMacro {

    /// A stored property to encode or decode.
    struct Property {

        /// Property name.
        let name: String

        /// Type name, without optional suffix.
        let type: String

        /// Whether the declared type is optional.
        let isOptional: Bool
    }

    /// Collects stored instance properties in declaration order.
    static func storedProperties(
        of declaration: some DeclGroupSyntax
    ) throws -> [Property] {
        var properties = [Property]()
        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                  else { continue }
            // skip static and computed properties
            guard varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) == false,
                  binding.accessorBlock == nil
                  else { continue }
            // skip constants with a default value, which cannot be assigned in an initializer
            if varDecl.bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
                continue
            }
            guard let typeSyntax = binding.typeAnnotation?.type else {
                throw MacroError.missingTypeAnnotation(for: identifier)
            }
            let rawTypeName = typeSyntax.description.trimmingCharacters(in: .whitespacesAndNewlines)
            // Strip Optional
            let typeName: String
            let isOptional: Bool
            if rawTypeName.hasPrefix("Optional<"), rawTypeName.hasSuffix(">") {
                typeName = String(rawTypeName.dropFirst("Optional<".count).dropLast())
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                isOptional = true
            } else if rawTypeName.hasSuffix("?") {
                typeName = String(rawTypeName.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                isOptional = true
            } else {
                typeName = rawTypeName
                isOptional = false
            }
            properties.append(Property(name: identifier, type: typeName, isOptional: isOptional))
        }
        return properties
    }

    /// Whether the declaration already defines `CodingKeys`.
    static func hasCodingKeys(
        _ declaration: some DeclGroupSyntax
    ) -> Bool {
        for member in declaration.memberBlock.members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "CodingKeys" {
                return true
            }
            if let typealiasDecl = member.decl.as(TypeAliasDeclSyntax.self),
               typealiasDecl.name.text == "CodingKeys" {
                return true
            }
        }
        return false
    }

    /// Access control prefix for generated members (`public `, `package ` or empty).
    static func accessPrefix(
        of declaration: some DeclGroupSyntax
    ) -> String {
        for modifier in declaration.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open):
                return "public "
            case .keyword(.package):
                return "package "
            default:
                continue
            }
        }
        return ""
    }

    static func codingKeysDeclarationSyntax(
        for properties: [Property],
        of declaration: some DeclGroupSyntax
    ) -> DeclSyntax {
        let access = accessPrefix(of: declaration)
        var lines = [String]()
        lines.append("\(access)enum CodingKeys: UInt8, TLVCoding.TLVCodingKey {")
        for (index, property) in properties.enumerated() {
            lines.append("    case \(property.name) = \(index)")
        }
        lines.append("}")
        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    static func initDeclarationSyntax(
        for properties: [Property],
        of declaration: some DeclGroupSyntax
    ) -> DeclSyntax {
        let access = accessPrefix(of: declaration)
        var lines = [String]()
        lines.append("\(access)init?(tlvData: Data) {")
        lines.append("    guard let container = TLVContainer(data: tlvData) else {")
        lines.append("        return nil")
        lines.append("    }")
        for property in properties {
            if property.isOptional {
                lines.append("    if container.contains(CodingKeys.\(property.name)) {")
                lines.append("        guard let \(property.name) = container.decode(\(property.type).self, forKey: CodingKeys.\(property.name)) else {")
                lines.append("            return nil")
                lines.append("        }")
                lines.append("        self.\(property.name) = \(property.name)")
                lines.append("    } else {")
                lines.append("        self.\(property.name) = nil")
                lines.append("    }")
            } else {
                lines.append("    guard let \(property.name) = container.decode(\(property.type).self, forKey: CodingKeys.\(property.name)) else {")
                lines.append("        return nil")
                lines.append("    }")
                lines.append("    self.\(property.name) = \(property.name)")
            }
        }
        lines.append("}")
        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }

    static func tlvDataDeclarationSyntax(
        for properties: [Property],
        of declaration: some DeclGroupSyntax
    ) -> DeclSyntax {
        let access = accessPrefix(of: declaration)
        var lines = [String]()
        lines.append("\(access)var tlvData: Data {")
        lines.append("    var container = TLVContainer()")
        for property in properties {
            lines.append("    container.encode(self.\(property.name), forKey: CodingKeys.\(property.name))")
        }
        lines.append("    return container.data")
        lines.append("}")
        return DeclSyntax(stringLiteral: lines.joined(separator: "\n"))
    }
}
