//
//  TLVCoding.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

#if canImport(Foundation) && !hasFeature(Embedded)
@_exported import struct Foundation.Data
#endif

/// Type-Length-Value Codable
public typealias TLVCodable = TLVEncodable & TLVDecodable

/// TLV Decodable type
///
/// A type that can initialize itself from a TLV8 binary payload.
/// Conformances are either written by hand or generated with the `@TLVCodable` macro.
public protocol TLVDecodable {

    init?(tlvData: Data)
}

/// TLV Encodable type
///
/// A type that can encode itself into a TLV8 binary payload.
/// Conformances are either written by hand or generated with the `@TLVCodable` macro.
public protocol TLVEncodable {

    var tlvData: Data { get }
}

// MARK: - RawRepresentable

public extension TLVEncodable where Self: RawRepresentable, RawValue: TLVEncodable {

    var tlvData: Data {
        rawValue.tlvData
    }
}

public extension TLVDecodable where Self: RawRepresentable, RawValue: TLVDecodable {

    init?(tlvData: Data) {
        guard let rawValue = RawValue(tlvData: tlvData) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
