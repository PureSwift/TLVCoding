//
//  Decoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// TLV8 Decoder
public struct TLVDecoder {
    
    // MARK: - Properties
    
    /// Any contextual information set by the user for encoding.
    public var userInfo = [CodingUserInfoKey : Any]()
    
    /// Logger handler
    public var log: ((String) -> ())?
    
    /// Format for numeric values.
    public var numericFormatting: TLVNumericFormatting = .default
    
    /// Format for UUID values.
    public var uuidFormatting: TLVUUIDFormatting = .default
    
    /// Format for Date values.
    public var dateFormatting: TLVDateFormatting = .default
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Methods
    
    public func decode <T: Decodable> (_ type: T.Type, from data: Data) throws -> T {
        
        log?("Will decode \(String(reflecting: T.self))")
        
        let items = try decode(data)
        
        let options = Decoder.Options(
            numericFormatting: numericFormatting,
            uuidFormatting: uuidFormatting,
            dateFormatting: dateFormatting
        )
        
        let decoder = Decoder(referencing: .items(items),
                              userInfo: userInfo,
                              log: log,
                              options: options)
        
        // decode from container
        return try T.init(from: decoder)
    }
    
    public func decode(_ data: Data) throws -> [TLVItem] {
        
        return try TLVDecoder.decode(data, codingPath: [])
    }
    
    internal static func decode(_ data: Data, codingPath: [CodingKey]) throws -> [TLVItem] {
        
        var offset = 0
        var items = [TLVItem]()
        
        while offset < data.count {
            
            // validate size
            guard data.count >= offset + 2 else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Not enough bytes (\(data.count)) to continue parsing at offset \(offset)"))
            }
            
            // get type
            let typeByte = data[offset] // 0
            offset += 1
            
            let length = Int(data[offset]) // 1
            offset += 1
            
            let valueData: Data
            
            if length > 0 {
                
                // validate size
                guard data.count >= offset + length else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Not enough bytes (\(data.count)) to continue parsing at offset \(offset)"))
                }
                
                // get value
                valueData = Data(data[offset ..< offset + length])
                
            } else {
                
                valueData = Data()
            }
            
            let item = TLVItem(type: TLVTypeCode(rawValue: typeByte), value: valueData)
            
            // append result
            items.append(item)
            
            // adjust offset for next value
            offset += length
        }
        
        return items
    }
}

// MARK: - Deprecated

public extension TLVDecoder {
    
    @available(*, deprecated, message: "Renamed to numericFormatting")
    var numericFormat: TLVNumericFormat {
        get { return numericFormatting }
        set { numericFormatting = newValue }
    }
    
    @available(*, deprecated, message: "Renamed to uuidFormatting")
    var uuidFormat: TLVUUIDFormat {
        get { return uuidFormatting }
        set { uuidFormatting = newValue }
    }
    
    @available(*, deprecated, message: "Renamed to dateFormatting")
    var dateFormat: TLVDateFormat {
        get { return dateFormatting }
        set { dateFormatting = newValue }
    }
}

// MARK: - Combine

#if canImport(Combine)
import Combine

extension TLVDecoder: TopLevelDecoder { }
#endif

// MARK: - Decoder

internal extension TLVDecoder {
    
    final class Decoder: Swift.Decoder {
        
        /// The path of coding keys taken to get to this point in decoding.
        fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for decoding.
        let userInfo: [CodingUserInfoKey : Any]
        
        fileprivate var stack: Stack
        
        /// Logger
        let log: ((String) -> ())?
        
        let options: Options
        
        // MARK: - Initialization
        
        fileprivate init(referencing container: Stack.Container,
                         at codingPath: [CodingKey] = [],
                         userInfo: [CodingUserInfoKey : Any],
                         log: ((String) -> ())?,
                         options: Options) {
            
            self.stack = Stack(container)
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
            self.options = options
        }
        
        // MARK: - Methods
        
        func container <Key: CodingKey> (keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
            
            log?("Requested container keyed by \(type.sanitizedName) for path \"\(codingPath.path)\"")
            
            let container = self.stack.top
            
            switch container {
            case let .items(items):
                let keyedContainer = TLVKeyedDecodingContainer<Key>(referencing: self, wrapping: items)
                return KeyedDecodingContainer(keyedContainer)
            case let .item(item):
                let items = try decode(item.value, codingPath: codingPath)
                let keyedContainer = TLVKeyedDecodingContainer<Key>(referencing: self, wrapping: items)
                return KeyedDecodingContainer(keyedContainer)
            }
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            
            log?("Requested unkeyed container for path \"\(codingPath.path)\"")
            
            let container = self.stack.top
            
            switch container {
                
            case let .items(items):
                
                return TLVUnkeyedDecodingContainer(referencing: self, wrapping: items)
                
            case let .item(item):
                
                // forceably cast to array
                do {
                    let items = try TLVDecoder.decode(item.value, codingPath: codingPath)
                    self.stack.pop() // replace stack
                    self.stack.push(.items(items))
                    return TLVUnkeyedDecodingContainer(referencing: self, wrapping: items)
                } catch {
                    log?("Could not decode for unkeyed container: \(error)")
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get unkeyed decoding container, invalid top container \(container)."))
                }
            }
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            
            log?("Requested single value container for path \"\(codingPath.path)\"")
            
            let container = self.stack.top
            
            guard case let .item(item) = container else {
                
                throw DecodingError.typeMismatch(SingleValueDecodingContainer.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get single value decoding container, invalid top container \(container)."))
            }
            
            return TLVSingleValueDecodingContainer(referencing: self, wrapping: item)
        }
    }
}

internal extension TLVDecoder.Decoder {
    
    struct Options {
        
        let numericFormatting: TLVNumericFormatting
        
        let uuidFormatting: TLVUUIDFormatting
        
        let dateFormatting: TLVDateFormatting
    }
}

// MARK: - Coding Key

internal extension TLVDecoder.Decoder {
    
    func typeCode <Key: CodingKey> (for key: Key) throws -> TLVTypeCode {
        
        guard let typeCode = TLVTypeCode(codingKey: key) else {
            if let intValue = key.intValue {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Coding key \(key) has an invalid integer value \(intValue)"))
            } else {
                throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Coding key \(key) has no integer value"))
            }
        }
        return typeCode
    }
}

// MARK: - Unboxing Values

internal extension TLVDecoder.Decoder {
    
    func unbox <T: TLVRawDecodable> (_ data: Data, as type: T.Type) throws -> T {
        
        guard let value = T.init(tlvData: data) else {
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Could not parse \(type) from \(data)"))
        }
        
        return value
    }
    
    func unboxNumeric <T: TLVRawDecodable & FixedWidthInteger> (_ data: Data, as type: T.Type) throws -> T {
        
        var numericValue = try unbox(data, as: type)
        switch options.numericFormatting {
        case .bigEndian:
            numericValue = T.init(bigEndian: numericValue)
        case .littleEndian:
            numericValue = T.init(littleEndian: numericValue)
        }
        return numericValue
    }
    
    func unboxDouble(_ data: Data) throws -> Double {
        let bitPattern = try unboxNumeric(data, as: UInt64.self)
        return Double(bitPattern: bitPattern)
    }
    
    func unboxFloat(_ data: Data) throws -> Float {
        let bitPattern = try unboxNumeric(data, as: UInt32.self)
        return Float(bitPattern: bitPattern)
    }
    
    /// Attempt to decode native value to expected type.
    func unboxDecodable <T: Decodable> (_ item: TLVItem, as type: T.Type) throws -> T {
        
        // override for native types
        if type == Data.self {
            return item.value as! T // In this case T is Data
        } else if type == UUID.self {
            return try unboxUUID(item.value) as! T
        } else if type == Date.self {
            return try unboxDate(item.value) as! T
        } else if let tlvCodable = type as? TLVCodable.Type {
            guard let value = tlvCodable.init(tlvData: item.value) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid data for \(String(reflecting: type))"))
            }
            return value as! T
        } else {
            // push container to stack and decode using Decodable implementation
            stack.push(.item(item))
            let decoded = try T(from: self)
            stack.pop()
            return decoded
        }
    }
}

private extension TLVDecoder.Decoder {
    
    func unboxUUID(_ data: Data) throws -> UUID {
        
        switch options.uuidFormatting {
        case .bytes:
            guard data.count == MemoryLayout<uuid_t>.size else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Invalud number of bytes (\(data.count)) for UUID"))
            }
            return UUID(uuid: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]))
        case .string:
            guard let string = String(tlvData: data) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid string data for UUID"))
            }
            guard let uuid = UUID(uuidString: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid UUID string \(string)"))
            }
            return uuid
        }
    }
    
    func unboxDate(_ data: Data) throws -> Date {
        
        switch options.dateFormatting {
        case .secondsSince1970:
            let timeInterval = try unboxDouble(data)
            return Date(timeIntervalSince1970: timeInterval)
        case .millisecondsSince1970:
            let timeInterval = try unboxDouble(data)
            return Date(timeIntervalSince1970: timeInterval / 1000)
        #if !os(WASI)
        case .iso8601:
            guard #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
                else { fatalError("ISO8601DateFormatter is unavailable on this platform.") }
            return try unboxDate(data, using: TLVDateFormatting.iso8601Formatter)
        case let .formatted(formatter):
            return try unboxDate(data, using: formatter)
        #endif
        }
    }
    
    #if !os(WASI)
    func unboxDate <T: DateFormatterProtocol> (_ data: Data, using formatter: T) throws -> Date {
        let string = try unbox(data, as: String.self)
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Invalid Date string \(string)"))
        }
        return date
    }
    #endif
}

// MARK: - Stack

private extension TLVDecoder {
    
    struct Stack {
        
        private(set) var containers = [Container]()
        
        fileprivate init(_ container: Container) {
            
            self.containers = [container]
        }
        
        var top: Container {
            
            guard let container = containers.last
                else { fatalError("Empty container stack.") }
            
            return container
        }
        
        mutating func push(_ container: Container) {
            
            containers.append(container)
        }
        
        @discardableResult
        mutating func pop() -> Container {
            
            guard let container = containers.popLast()
                else { fatalError("Empty container stack.") }
            
            return container
        }
    }
}

fileprivate extension TLVDecoder.Stack {
    
    enum Container {
        
        case items([TLVItem])
        case item(TLVItem)
    }
}


// MARK: - KeyedDecodingContainer

internal struct TLVKeyedDecodingContainer <K: CodingKey> : KeyedDecodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the encoder we're reading from.
    let decoder: TLVDecoder.Decoder
    
    /// A reference to the container we're reading from.
    let container: [TLVItem]
    
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    /// All the keys the Decoder has for this container.
    let allKeys: [Key]
    
    // MARK: Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: TLVDecoder.Decoder, wrapping container: [TLVItem]) {
        
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.allKeys = container.compactMap { Key(intValue: Int($0.type.rawValue)) }
    }
    
    // MARK: KeyedDecodingContainerProtocol
    
    func contains(_ key: Key) -> Bool {
        
        self.decoder.log?("Check whether key \"\(key.stringValue)\" exists")
        guard let typeCode = try? self.decoder.typeCode(for: key)
            else { return false }
        return container.contains { $0.type == typeCode }
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        
        // set coding key context
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        self.decoder.log?("Check if nil at path \"\(decoder.codingPath.path)\"")
        
        // check if key exists since there is no way to represent nil in TLV
        // empty data and strings should not be falsely reported as nil
        return try self.value(for: key) == nil
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        
        return try decodeTLV(type, forKey: key)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        
        let value = try decodeNumeric(Int32.self, forKey: key)
        return Int(value)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        
        return try decodeTLV(type, forKey: key)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        
        let value = try decodeNumeric(UInt32.self, forKey: key)
        return UInt(value)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        
        return try decodeTLV(type, forKey: key)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        
        return try decodeNumeric(type, forKey: key)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        
        let bitPattern = try decodeNumeric(UInt32.self, forKey: key)
        return Float(bitPattern: bitPattern)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        
        let bitPattern = try decodeNumeric(UInt64.self, forKey: key)
        return Double(bitPattern: bitPattern)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        
        return try decodeTLV(type, forKey: key)
    }
    
    func decode <T: Decodable> (_ type: T.Type, forKey key: Key) throws -> T {
        
        return try self.value(for: key, type: type) { try decoder.unboxDecodable($0, as: type) }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        
        fatalError()
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        
        fatalError()
    }
    
    // MARK: Private Methods
    
    /// Decode native value type from TLV data.
    private func decodeTLV <T: TLVRawDecodable> (_ type: T.Type, forKey key: Key) throws -> T {
        
        return try self.value(for: key, type: type) { try decoder.unbox($0.value, as: type) }
    }
    
    private func decodeNumeric <T: TLVRawDecodable & FixedWidthInteger> (_ type: T.Type, forKey key: Key) throws -> T {
        
        return try self.value(for: key, type: type) { try decoder.unboxNumeric($0.value, as: type) }
    }
    
    /// Access actual value
    @inline(__always)
    private func value <T> (for key: Key, type: T.Type, decode: (TLVItem) throws -> T) throws -> T {
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        decoder.log?("Will read value at path \"\(decoder.codingPath.path)\"")
        guard let item = try self.value(for: key) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }
        return try decode(item)
    }
    
    /// Access actual value
    private func value(for key: Key) throws -> TLVItem? {
        let typeCode = try self.decoder.typeCode(for: key)
        return container.first { $0.type == typeCode }
    }
}

// MARK: - SingleValueDecodingContainer

internal struct TLVSingleValueDecodingContainer: SingleValueDecodingContainer {
    
    // MARK: Properties
    
    /// A reference to the decoder we're reading from.
    let decoder: TLVDecoder.Decoder
    
    /// A reference to the container we're reading from.
    let container: TLVItem
    
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    // MARK: Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: TLVDecoder.Decoder, wrapping container: TLVItem) {
        
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }
    
    // MARK: SingleValueDecodingContainer
    
    func decodeNil() -> Bool {
        
        return container.value.isEmpty
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        
        return try self.decoder.unbox(container.value, as: type)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        
        let value = try self.decoder.unboxNumeric(container.value, as: Int32.self)
        return Int(value)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        
        return try self.decoder.unbox(container.value, as: type)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        
        return try self.decoder.unboxNumeric(container.value, as: type)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        
        return try self.decoder.unboxNumeric(container.value, as: type)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        
        return try self.decoder.unboxNumeric(container.value, as: type)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        
        let value = try self.decoder.unboxNumeric(container.value, as: UInt32.self)
        return UInt(value)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        
        return try self.decoder.unbox(container.value, as: type)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        
        return try self.decoder.unboxNumeric(container.value, as: type)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        
        return try self.decoder.unboxNumeric(container.value, as: type)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        
        return try self.decoder.unboxNumeric(container.value, as: type)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        
        let value = try self.decoder.unboxNumeric(container.value, as: UInt32.self)
        return Float(bitPattern: value)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        
        let value = try self.decoder.unboxNumeric(container.value, as: UInt64.self)
        return Double(bitPattern: value)
    }
    
    func decode(_ type: String.Type) throws -> String {
        
        return try self.decoder.unbox(container.value, as: type)
    }
    
    func decode <T : Decodable> (_ type: T.Type) throws -> T {
        
        return try self.decoder.unboxDecodable(container, as: type)
    }
}

// MARK: UnkeyedDecodingContainer

internal struct TLVUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    // MARK: Properties
    
    /// A reference to the encoder we're reading from.
    let decoder: TLVDecoder.Decoder
    
    /// A reference to the container we're reading from.
    let container: [TLVItem]
    
    /// The path of coding keys taken to get to this point in decoding.
    let codingPath: [CodingKey]
    
    private(set) var currentIndex: Int = 0
    
    // MARK: Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: TLVDecoder.Decoder, wrapping container: [TLVItem]) {
        
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }
    
    // MARK: UnkeyedDecodingContainer
    
    var count: Int? {
        return _count
    }
    
    private var _count: Int {
        return container.count
    }
    
    var isAtEnd: Bool {
        return currentIndex >= _count
    }
    
    mutating func decodeNil() throws -> Bool {
        
        try assertNotEnd()
        
        // never optional, decode
        return false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool { fatalError("stub") }
    mutating func decode(_ type: Int.Type) throws -> Int { fatalError("stub") }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { fatalError("stub") }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { fatalError("stub") }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { fatalError("stub") }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { fatalError("stub") }
    mutating func decode(_ type: UInt.Type) throws -> UInt { fatalError("stub") }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { fatalError("stub") }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { fatalError("stub") }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { fatalError("stub") }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { fatalError("stub") }
    mutating func decode(_ type: Float.Type) throws -> Float { fatalError("stub") }
    mutating func decode(_ type: Double.Type) throws -> Double { fatalError("stub") }
    mutating func decode(_ type: String.Type) throws -> String { fatalError("stub") }
    
    mutating func decode <T : Decodable> (_ type: T.Type) throws -> T {
        
        try assertNotEnd()
        
        self.decoder.codingPath.append(Index(intValue: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        let item = self.container[self.currentIndex]
        
        let decoded = try self.decoder.unboxDecodable(item, as: type)
        
        self.currentIndex += 1
        
        return decoded
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode \(type)"))
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        throw DecodingError.typeMismatch([Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode unkeyed container."))
    }
    
    mutating func superDecoder() throws -> Decoder {
        
        // set coding key context
        self.decoder.codingPath.append(Index(intValue: currentIndex))
        defer { self.decoder.codingPath.removeLast() }
        
        // log
        self.decoder.log?("Requested super decoder for path \"\(self.decoder.codingPath.path)\"")
        
        // check for end of array
        try assertNotEnd()
        
        // get item
        let item = container[currentIndex]
        
        // increment counter
        self.currentIndex += 1
        
        // create new decoder
        let decoder = TLVDecoder.Decoder(referencing: .item(item),
                                         at: self.decoder.codingPath,
                                         userInfo: self.decoder.userInfo,
                                         log: self.decoder.log,
                                         options: self.decoder.options)
        
        return decoder
    }
    
    // MARK: Private Methods
    
    @inline(__always)
    private func assertNotEnd() throws {
        
        guard isAtEnd == false else {
            
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [Index(intValue: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
    }
}

internal extension TLVUnkeyedDecodingContainer {
    
    struct Index: CodingKey {
        
        public let index: Int
        
        public init(intValue: Int) {
            self.index = intValue
        }
        
        public init?(stringValue: String) {
            return nil
        }
        
        public var intValue: Int? {
            return index
        }
        
        public var stringValue: String {
            return "\(index)"
        }
    }
}

// MARK: - Decodable Types

/// Private protocol for decoding TLV values into raw data.
internal protocol TLVRawDecodable {
    
    init?(tlvData data: Data)
}

extension String: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        self.init(data: data, encoding: .utf8)
    }
}

extension Bool: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<UInt8>.size
            else { return nil }
        
        self = data[0] != 0
    }
}

extension UInt8: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<UInt8>.size
            else { return nil }
        
        self = data[0]
    }
}

extension UInt16: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<UInt16>.size
            else { return nil }
        
        self.init(bytes: (data[0], data[1]))
    }
}

extension UInt32: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<UInt32>.size
            else { return nil }
        
        self.init(bytes: (data[0], data[1], data[2], data[3]))
    }
}

extension UInt64: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<UInt64>.size
            else { return nil }
        
        self.init(bytes: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]))
    }
}

extension Int8: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<Int8>.size
            else { return nil }
        
        self = Int8(bitPattern: data[0])
    }
}

extension Int16: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<Int16>.size
            else { return nil }
        
        self.init(bytes: (data[0], data[1]))
    }
}

extension Int32: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<Int32>.size
            else { return nil }
        
        self.init(bytes: (data[0], data[1], data[2], data[3]))
    }
}

extension Int64: TLVRawDecodable {
    
    public init?(tlvData data: Data) {
        
        guard data.count == MemoryLayout<Int64>.size
            else { return nil }
        
        self.init(bytes: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]))
    }
}
