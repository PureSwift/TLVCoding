//
//  CodingKey.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

/// TLV Coding Key
///
/// A key identifying a TLV8 item within a container.
/// Typically implemented as a `UInt8` raw value enum:
///
/// ```swift
/// enum CodingKeys: UInt8, TLVCodingKey {
///     case state  = 0x01
///     case result = 0x02
/// }
/// ```
public protocol TLVCodingKey: Sendable {

    init?(code: TLVTypeCode)

    var code: TLVTypeCode { get }
}

public extension TLVCodingKey where Self: RawRepresentable, Self.RawValue == TLVTypeCode.RawValue {

    init?(code: TLVTypeCode) {
        self.init(rawValue: code.rawValue)
    }

    var code: TLVTypeCode {
        TLVTypeCode(rawValue: rawValue)
    }
}

// MARK: - TLVTypeCode

extension TLVTypeCode: TLVCodingKey {

    public init(code: TLVTypeCode) {
        self = code
    }

    public var code: TLVTypeCode {
        self
    }
}
