//
//  Error.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

/// TLVCoding macro error
enum MacroError: Error, CustomStringConvertible {

    case invalidType
    case noStoredProperties
    case missingTypeAnnotation(for: String)

    var description: String {
        switch self {
        case .invalidType:
            return "@TLVCodable can only be applied to a struct"
        case .noStoredProperties:
            return "@TLVCodable requires at least one stored property"
        case let .missingTypeAnnotation(propertyName):
            return "Stored property '\(propertyName)' requires an explicit type annotation"
        }
    }
}
