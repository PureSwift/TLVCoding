//
//  Primitives.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if canImport(FoundationEssentials) && !hasFeature(Embedded)
import FoundationEssentials
#elseif canImport(Foundation) && !hasFeature(Embedded)
import Foundation
#endif

// MARK: - FixedWidthInteger

internal extension FixedWidthInteger {

    /// Initialize from a little-endian TLV payload of exactly `MemoryLayout<Self>.size` bytes.
    init?(littleEndianTLV tlvData: Data) {
        guard tlvData.count == MemoryLayout<Self>.size else {
            return nil
        }
        var value = Self.zero
        withUnsafeMutableBytes(of: &value) { buffer in
            var index = tlvData.startIndex
            for offset in 0 ..< buffer.count {
                buffer[offset] = tlvData[index]
                index = tlvData.index(after: index)
            }
        }
        self.init(littleEndian: value)
    }

    /// Little-endian TLV payload.
    var littleEndianTLV: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}

// MARK: - Integers

extension UInt8: TLVCodable {

    public init?(tlvData: Data) {
        guard tlvData.count == 1 else { return nil }
        self = tlvData[tlvData.startIndex]
    }

    public var tlvData: Data {
        Data([self])
    }
}

extension UInt16: TLVCodable {

    public init?(tlvData: Data) {
        self.init(littleEndianTLV: tlvData)
    }

    public var tlvData: Data {
        littleEndianTLV
    }
}

extension UInt32: TLVCodable {

    public init?(tlvData: Data) {
        self.init(littleEndianTLV: tlvData)
    }

    public var tlvData: Data {
        littleEndianTLV
    }
}

extension UInt64: TLVCodable {

    public init?(tlvData: Data) {
        self.init(littleEndianTLV: tlvData)
    }

    public var tlvData: Data {
        littleEndianTLV
    }
}

extension Int8: TLVCodable {

    public init?(tlvData: Data) {
        guard tlvData.count == 1 else { return nil }
        self = Int8(bitPattern: tlvData[tlvData.startIndex])
    }

    public var tlvData: Data {
        Data([UInt8(bitPattern: self)])
    }
}

extension Int16: TLVCodable {

    public init?(tlvData: Data) {
        self.init(littleEndianTLV: tlvData)
    }

    public var tlvData: Data {
        littleEndianTLV
    }
}

extension Int32: TLVCodable {

    public init?(tlvData: Data) {
        self.init(littleEndianTLV: tlvData)
    }

    public var tlvData: Data {
        littleEndianTLV
    }
}

extension Int64: TLVCodable {

    public init?(tlvData: Data) {
        self.init(littleEndianTLV: tlvData)
    }

    public var tlvData: Data {
        littleEndianTLV
    }
}

/// `Int` is encoded as a 32-bit little-endian integer for a stable wire format across platforms.
extension Int: TLVCodable {

    public init?(tlvData: Data) {
        guard let value = Int32(littleEndianTLV: tlvData) else { return nil }
        self.init(value)
    }

    public var tlvData: Data {
        Int32(self).littleEndianTLV
    }
}

/// `UInt` is encoded as a 32-bit little-endian integer for a stable wire format across platforms.
extension UInt: TLVCodable {

    public init?(tlvData: Data) {
        guard let value = UInt32(littleEndianTLV: tlvData) else { return nil }
        self.init(value)
    }

    public var tlvData: Data {
        UInt32(self).littleEndianTLV
    }
}

// MARK: - Bool

extension Bool: TLVCodable {

    public init?(tlvData: Data) {
        guard tlvData.count == 1 else { return nil }
        self = tlvData[tlvData.startIndex] != 0
    }

    public var tlvData: Data {
        Data([self ? 1 : 0])
    }
}

// MARK: - Floating Point

extension Float: TLVCodable {

    public init?(tlvData: Data) {
        guard let bitPattern = UInt32(littleEndianTLV: tlvData) else { return nil }
        self.init(bitPattern: bitPattern)
    }

    public var tlvData: Data {
        bitPattern.littleEndianTLV
    }
}

extension Double: TLVCodable {

    public init?(tlvData: Data) {
        guard let bitPattern = UInt64(littleEndianTLV: tlvData) else { return nil }
        self.init(bitPattern: bitPattern)
    }

    public var tlvData: Data {
        bitPattern.littleEndianTLV
    }
}

// MARK: - String

extension String: TLVCodable {

    public init?(tlvData: Data) {
        self.init(decoding: tlvData, as: UTF8.self)
    }

    public var tlvData: Data {
        Data(utf8)
    }
}

// MARK: - Data

extension Data: TLVCodable {

    public init?(tlvData: Data) {
        self = tlvData
    }

    public var tlvData: Data {
        self
    }
}

// MARK: - Array

extension Array: TLVEncodable where Element: TLVEncodable {

    /// Encodes each element as a TLV item keyed by its index.
    public var tlvData: Data {
        var container = TLVContainer()
        for (index, element) in enumerated() {
            container.items.append(
                TLVItem(
                    type: TLVTypeCode(rawValue: UInt8(index)),
                    value: element.tlvData
                )
            )
        }
        return container.data
    }
}

extension Array: TLVDecodable where Element: TLVDecodable {

    public init?(tlvData: Data) {
        guard let container = TLVContainer(data: tlvData) else {
            return nil
        }
        var elements = [Element]()
        elements.reserveCapacity(container.items.count)
        for item in container.items {
            guard let element = Element(tlvData: item.value) else {
                return nil
            }
            elements.append(element)
        }
        self = elements
    }
}
