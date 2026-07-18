//
//  Container.swift
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

/**
 TLV8 keyed coding container.

 An ordered collection of ``TLVItem`` values used to explicitly encode and decode
 structured types without `Codable`.

 ```swift
 // Encoding
 var container = TLVContainer()
 container.encode(gender, forKey: CodingKeys.gender)
 container.encode(name, forKey: CodingKeys.name)
 let data = container.data

 // Decoding
 guard let container = TLVContainer(data: data),
       let gender = container.decode(Gender.self, forKey: CodingKeys.gender),
       let name = container.decode(String.self, forKey: CodingKeys.name)
       else { return nil }
 ```
 */
public struct TLVContainer: Equatable, Hashable, Sendable {

    /// TLV items, in encoding order.
    public var items: [TLVItem]

    /// Initialize an empty container.
    public init() {
        self.items = []
    }

    /// Initialize with the specified items.
    public init(items: [TLVItem]) {
        self.items = items
    }

    /// Parse a container from TLV8 data.
    public init?(data: Data) {
        var items = [TLVItem]()
        var index = data.startIndex
        while index < data.endIndex {
            // read type and length bytes
            let type = TLVTypeCode(rawValue: data[index])
            index = data.index(after: index)
            guard index < data.endIndex else {
                return nil // missing length byte
            }
            let length = Int(data[index])
            index = data.index(after: index)
            // read value payload
            guard let valueEnd = data.index(index, offsetBy: length, limitedBy: data.endIndex) else {
                return nil // truncated value
            }
            items.append(TLVItem(type: type, value: Data(data[index ..< valueEnd])))
            index = valueEnd
        }
        self.items = items
    }
}

public extension TLVContainer {

    /// Serialized TLV8 data.
    var data: Data {
        var data = Data()
        data.reserveCapacity(items.reduce(0) { $0 + $1.dataLength })
        for item in items {
            item.append(to: &data)
        }
        return data
    }
}

// MARK: - Keyed Access

public extension TLVContainer {

    /// The value payload of the first item with the specified type code, if any.
    subscript(code: TLVTypeCode) -> Data? {
        items.first(where: { $0.type == code })?.value
    }

    /// Whether the container includes an item for the specified key.
    func contains<K: TLVCodingKey>(_ key: K) -> Bool {
        items.contains(where: { $0.type == key.code })
    }
}

// MARK: - Encoding

public extension TLVContainer {

    /// Append the encoded value for the specified key.
    mutating func encode<T: TLVEncodable, K: TLVCodingKey>(_ value: T, forKey key: K) {
        items.append(TLVItem(type: key.code, value: value.tlvData))
    }

    /// Append the encoded value for the specified key, skipping `nil`.
    mutating func encode<T: TLVEncodable, K: TLVCodingKey>(_ value: T?, forKey key: K) {
        guard let value else { return }
        encode(value, forKey: key)
    }
}

// MARK: - Decoding

public extension TLVContainer {

    /// Decode the value for the specified key.
    ///
    /// Returns `nil` if the key is missing or the payload is invalid for the specified type.
    func decode<T: TLVDecodable, K: TLVCodingKey>(_ type: T.Type, forKey key: K) -> T? {
        guard let value = self[key.code] else {
            return nil
        }
        return T(tlvData: value)
    }

    /// Decode an optional value for the specified key.
    ///
    /// Returns `.some(nil)` if the key is missing,
    /// `nil` if the payload is present but invalid for the specified type.
    func decodeIfPresent<T: TLVDecodable, K: TLVCodingKey>(_ type: T.Type, forKey key: K) -> T?? {
        guard let value = self[key.code] else {
            return .some(nil)
        }
        guard let decoded = T(tlvData: value) else {
            return nil
        }
        return .some(decoded)
    }
}

// MARK: - TLVCodable

extension TLVContainer: TLVCodable {

    public init?(tlvData: Data) {
        self.init(data: tlvData)
    }

    public var tlvData: Data {
        data
    }
}
