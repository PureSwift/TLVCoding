//
//  TypeCode.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

/// TLV8 type code
public struct TLVTypeCode: RawRepresentable, Equatable, Hashable, Sendable {

    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension TLVTypeCode: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt8) {
        self.init(rawValue: value)
    }
}
