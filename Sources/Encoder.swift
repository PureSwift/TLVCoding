//
//  Encoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// TLV8 Encoder
public struct TLVEncoder {
    
    // MARK: - Properties
    
    /// Any contextual information set by the user for encoding.
    public var userInfo = [CodingUserInfoKey : Any]()
    
    /// Logger handler
    public var log: ((String) -> ())?
    
    /// Format for numeric values.
    public var outputFormatting: TLVOutputFormatting = .default
    
    /// Format for numeric values.
    public var numericFormatting: TLVNumericFormatting = .default
    
    /// Format for UUID values.
    public var uuidFormatting: TLVUUIDFormatting = .default
    
    /// Format for Date values.
    public var dateFormatting: TLVDateFormatting = .default
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Methods
    
    public func encode <T: Encodable> (_ value: T) throws -> Data {
        
        log?("Will encode \(String(reflecting: T.self))")
        
        let options = Encoder.Options(
            outputFormatting: outputFormatting,
            numericFormatting: numericFormatting,
            uuidFormatting: uuidFormatting,
            dateFormatting: dateFormatting
        )
        
        let encoder = Encoder(userInfo: userInfo, log: log, options: options)
        try value.encode(to: encoder)
        assert(encoder.stack.containers.count == 1)
        
        guard case let .items(container) = encoder.stack.root else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) is not encoded as items."))
        }
        
        return container.data
    }
    
    public func encode(_ items: [TLVItem]) -> Data {
        return Data(items)
    }
    
    public func encode(_ items: TLVItem...) -> Data {
        return Data(items)
    }
}

// MARK: - Deprecated

public extension TLVEncoder {
    
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

extension TLVEncoder: TopLevelEncoder { }
#endif

// MARK: - Encoder

internal extension TLVEncoder {
    
    final class Encoder: Swift.Encoder {
        
        // MARK: - Properties
        
        /// The path of coding keys taken to get to this point in encoding.
        fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for encoding.
        let userInfo: [CodingUserInfoKey : Any]
        
        /// Logger
        let log: ((String) -> ())?
        
        let options: Options
        
        private(set) var stack: Stack
        
        // MARK: - Initialization
        
        init(codingPath: [CodingKey] = [],
             userInfo: [CodingUserInfoKey : Any],
             log: ((String) -> ())?,
             options: Options) {
            
            self.stack = Stack()
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
            self.options = options
        }
        
        // MARK: - Encoder
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            
            log?("Requested container keyed by \(type.sanitizedName) for path \"\(codingPath.path)\"")
            
            let stackContainer = ItemsContainer()
            self.stack.push(.items(stackContainer))
            
            let keyedContainer = TLVKeyedContainer<Key>(referencing: self, wrapping: stackContainer)
            
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            
            log?("Requested unkeyed container for path \"\(codingPath.path)\"")
            
            let stackContainer = ItemsContainer()
            self.stack.push(.items(stackContainer))
            
            return TLVUnkeyedEncodingContainer(referencing: self, wrapping: stackContainer)
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            
            log?("Requested single value container for path \"\(codingPath.path)\"")
            
            let stackContainer = ItemContainer()
            self.stack.push(.item(stackContainer))
            
            return TLVSingleValueEncodingContainer(referencing: self, wrapping: stackContainer)
        }
    }
}

internal extension TLVEncoder.Encoder {
    
    struct Options {
        
        public let outputFormatting: TLVOutputFormatting
        
        public let numericFormatting: TLVNumericFormatting
        
        public let uuidFormatting: TLVUUIDFormatting
        
        public let dateFormatting: TLVDateFormatting
    }
}

internal extension TLVEncoder.Encoder {
    
    func typeCode <Key: CodingKey, T> (for key: Key, value: T) throws -> TLVTypeCode {
        
        guard let typeCode = TLVTypeCode(codingKey: key) else {
            if let intValue = key.intValue {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Coding key \(key) has an invalid integer value \(intValue)"))
            } else {
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Coding key \(key) has no integer value"))
            }
        }
        return typeCode
    }
}

internal extension TLVEncoder.Encoder {
    
    @inline(__always)
    func box <T: TLVRawEncodable> (_ value: T) -> Data {
        return value.tlvData
    }
    
    @inline(__always)
    func boxNumeric <T: TLVRawEncodable & FixedWidthInteger> (_ value: T) -> Data {
        
        let numericValue: T
        switch options.numericFormatting {
        case .bigEndian:
            numericValue = value.bigEndian
        case .littleEndian:
            numericValue = value.littleEndian
        }
        return box(numericValue)
    }
    
    @inline(__always)
    func boxDouble(_ double: Double) -> Data {
        return boxNumeric(double.bitPattern)
    }
    
    @inline(__always)
    func boxFloat(_ float: Float) -> Data {
        return boxNumeric(float.bitPattern)
    }
    
    func boxEncodable <T: Encodable> (_ value: T) throws -> Data {
        
        if let data = value as? Data {
            return data
        } else if let uuid = value as? UUID {
            return boxUUID(uuid)
        } else if let date = value as? Date {
            return boxDate(date)
        } else if let tlvEncodable = value as? TLVEncodable {
            return tlvEncodable.tlvData
        } else {
            // encode using Encodable, should push new container.
            try value.encode(to: self)
            let nestedContainer = stack.pop()
            return nestedContainer.data
        }
    }
}

private extension TLVEncoder.Encoder {
    
    func boxUUID(_ uuid: UUID) -> Data {
        
        switch options.uuidFormatting {
        case .bytes:
            return Data(uuid)
        case .string:
            return uuid.uuidString.tlvData
        }
    }
    
    func boxDate(_ date: Date) -> Data {
        
        switch options.dateFormatting {
        case .secondsSince1970:
            return boxDouble(date.timeIntervalSince1970)
        case .millisecondsSince1970:
            return boxDouble(date.timeIntervalSince1970 * 1000)
        #if !os(WASI)
        case .iso8601:
            guard #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
                else { fatalError("ISO8601DateFormatter is unavailable on this platform.") }
            return boxDate(date, using: TLVDateFormatting.iso8601Formatter)
        case let .formatted(formatter):
            return boxDate(date, using: formatter)
        #endif
        }
    }
    
    #if !os(WASI)
    func boxDate <T: DateFormatterProtocol> (_ date: Date, using formatter: T) -> Data {
        return box(formatter.string(from: date))
    }
    #endif
}

// MARK: - Stack

internal extension TLVEncoder.Encoder {
    
    struct Stack {
        
        private(set) var containers = [Container]()
        
        fileprivate init() { }
        
        var top: Container {
            
            guard let container = containers.last
                else { fatalError("Empty container stack.") }
            
            return container
        }
        
        var root: Container {
            
            guard let container = containers.first
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

internal extension TLVEncoder.Encoder {
    
    final class ItemsContainer {
        
        private(set) var items = [TLVItem]()
        
        init() { }
        
        var data: Data {
            return Data(items)
        }
        
        @inline(__always)
        func append(_ item: TLVItem, options: Options) {
            items.append(item)
            if options.outputFormatting.sortedKeys {
                items.sort(by: { $0.type.rawValue < $1.type.rawValue })
            }
        }
        
        @inline(__always)
        fileprivate func append(_ item: TLVItem) {
            items.append(item)
        }
    }
    
    final class ItemContainer {
        
        var data: Data
        
        init(_ data: Data = Data()) {
            
            self.data = data
        }
    }
    
    enum Container {
        
        case items(ItemsContainer)
        case item(ItemContainer)
        
        var data: Data {
            
            switch self {
            case let .items(container):
                return container.data
            case let .item(container):
                return container.data
            }
        }
    }
}

// MARK: - KeyedEncodingContainerProtocol

internal final class TLVKeyedContainer <K : CodingKey> : KeyedEncodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: - Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: TLVEncoder.Encoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    /// A reference to the container we're writing to.
    let container: TLVEncoder.Encoder.ItemsContainer
    
    // MARK: - Initialization
    
    init(referencing encoder: TLVEncoder.Encoder,
         wrapping container: TLVEncoder.Encoder.ItemsContainer) {
        
        self.encoder = encoder
        self.codingPath = encoder.codingPath
        self.container = container
    }
    
    // MARK: - Methods
    
    func encodeNil(forKey key: K) throws {
        // do nothing
    }
    
    func encode(_ value: Bool, forKey key: K) throws {
        try encodeTLV(value, forKey: key)
    }
    
    func encode(_ value: Int, forKey key: K) throws {
        try encodeNumeric(Int32(value), forKey: key)
    }
    
    func encode(_ value: Int8, forKey key: K) throws {
        try encodeTLV(value, forKey: key)
    }
    
    func encode(_ value: Int16, forKey key: K) throws {
        try encodeNumeric(value, forKey: key)
    }
    
    func encode(_ value: Int32, forKey key: K) throws {
        try encodeNumeric(value, forKey: key)
    }
    
    func encode(_ value: Int64, forKey key: K) throws {
        try encodeNumeric(value, forKey: key)
    }
    
    func encode(_ value: UInt, forKey key: K) throws {
        try encodeNumeric(UInt32(value), forKey: key)
    }
    
    func encode(_ value: UInt8, forKey key: K) throws {
        try encodeTLV(value, forKey: key)
    }
    
    func encode(_ value: UInt16, forKey key: K) throws {
        try encodeNumeric(value, forKey: key)
    }
    
    func encode(_ value: UInt32, forKey key: K) throws {
        try encodeNumeric(value, forKey: key)
    }
    
    func encode(_ value: UInt64, forKey key: K) throws {
        try encodeNumeric(value, forKey: key)
    }
    
    func encode(_ value: Float, forKey key: K) throws {
        try encodeNumeric(value.bitPattern, forKey: key)
    }
    
    func encode(_ value: Double, forKey key: K) throws {
        try encodeNumeric(value.bitPattern, forKey: key)
    }
    
    func encode(_ value: String, forKey key: K) throws {
        try encodeTLV(value, forKey: key)
    }
    
    func encode <T: Encodable> (_ value: T, forKey key: K) throws {
        
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        let data = try encoder.boxEncodable(value)
        try setValue(value, data: data, for: key)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        
        fatalError()
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        
        fatalError()
    }
    
    func superEncoder() -> Encoder {
        
        fatalError()
    }
    
    func superEncoder(forKey key: K) -> Encoder {
        
        fatalError()
    }
    
    // MARK: - Private Methods
    
    private func encodeNumeric <T: TLVRawEncodable & FixedWidthInteger> (_ value: T, forKey key: K) throws {
        
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        let data = encoder.boxNumeric(value)
        try setValue(value, data: data, for: key)
    }
    
    private func encodeTLV <T: TLVRawEncodable> (_ value: T, forKey key: K) throws {
        
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        let data = encoder.box(value)
        try setValue(value, data: data, for: key)
    }
    
    private func setValue <T> (_ value: T, data: Data, for key: Key) throws {
        
        encoder.log?("Will encode value for key \(key.stringValue) at path \"\(encoder.codingPath.path)\"")
        
        let type = try encoder.typeCode(for: key, value: value)
        let item = TLVItem(type: type, value: data)
        self.container.append(item, options: encoder.options)
    }
}

// MARK: - SingleValueEncodingContainer

internal final class TLVSingleValueEncodingContainer: SingleValueEncodingContainer {
    
    // MARK: - Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: TLVEncoder.Encoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    /// A reference to the container we're writing to.
    let container: TLVEncoder.Encoder.ItemContainer
    
    /// Whether the data has been written
    private var didWrite = false
    
    // MARK: - Initialization
    
    init(referencing encoder: TLVEncoder.Encoder,
         wrapping container: TLVEncoder.Encoder.ItemContainer) {
        
        self.encoder = encoder
        self.codingPath = encoder.codingPath
        self.container = container
    }
    
    // MARK: - Methods
    
    func encodeNil() throws {
        // do nothing
    }
    
    func encode(_ value: Bool) throws { write(encoder.box(value)) }
    
    func encode(_ value: String) throws { write(encoder.box(value)) }
    
    func encode(_ value: Double) throws { write(encoder.boxDouble(value)) }
    
    func encode(_ value: Float) throws { write(encoder.boxFloat(value)) }
    
    func encode(_ value: Int) throws { write(encoder.boxNumeric(Int32(value))) }
    
    func encode(_ value: Int8) throws { write(encoder.box(value)) }
    
    func encode(_ value: Int16) throws { write(encoder.boxNumeric(value)) }
    
    func encode(_ value: Int32) throws { write(encoder.boxNumeric(value)) }
    
    func encode(_ value: Int64) throws { write(encoder.boxNumeric(value)) }
    
    func encode(_ value: UInt) throws { write(encoder.boxNumeric(UInt32(value))) }
    
    func encode(_ value: UInt8) throws { write(encoder.box(value)) }
    
    func encode(_ value: UInt16) throws { write(encoder.boxNumeric(value)) }
    
    func encode(_ value: UInt32) throws { write(encoder.boxNumeric(value)) }
    
    func encode(_ value: UInt64) throws { write(encoder.boxNumeric(value)) }
    
    func encode <T: Encodable> (_ value: T) throws { write(try encoder.boxEncodable(value)) }
    
    // MARK: - Private Methods
    
    private func write(_ data: Data) {
        
        precondition(didWrite == false, "Data already written")
        self.container.data = data
        self.didWrite = true
    }
}

// MARK: - UnkeyedEncodingContainer

internal final class TLVUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    
    // MARK: - Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: TLVEncoder.Encoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    /// A reference to the container we're writing to.
    let container: TLVEncoder.Encoder.ItemsContainer
    
    // MARK: - Initialization
    
    init(referencing encoder: TLVEncoder.Encoder,
         wrapping container: TLVEncoder.Encoder.ItemsContainer) {
        
        self.encoder = encoder
        self.codingPath = encoder.codingPath
        self.container = container
    }
    
    // MARK: - Methods
    
    /// The number of elements encoded into the container.
    var count: Int {
        return container.items.count
    }
    
    func encodeNil() throws {
        // do nothing
    }
    
    func encode(_ value: Bool) throws { append(encoder.box(value)) }
    
    func encode(_ value: String) throws { append(encoder.box(value)) }
    
    func encode(_ value: Double) throws { append(encoder.boxNumeric(value.bitPattern)) }
    
    func encode(_ value: Float) throws { append(encoder.boxNumeric(value.bitPattern)) }
    
    func encode(_ value: Int) throws { append(encoder.boxNumeric(Int32(value))) }
    
    func encode(_ value: Int8) throws { append(encoder.box(value)) }
    
    func encode(_ value: Int16) throws { append(encoder.boxNumeric(value)) }
    
    func encode(_ value: Int32) throws { append(encoder.boxNumeric(value)) }
    
    func encode(_ value: Int64) throws { append(encoder.boxNumeric(value)) }
    
    func encode(_ value: UInt) throws { append(encoder.boxNumeric(UInt32(value))) }
    
    func encode(_ value: UInt8) throws { append(encoder.box(value)) }
    
    func encode(_ value: UInt16) throws { append(encoder.boxNumeric(value)) }
    
    func encode(_ value: UInt32) throws { append(encoder.boxNumeric(value)) }
    
    func encode(_ value: UInt64) throws { append(encoder.boxNumeric(value)) }
    
    func encode <T: Encodable> (_ value: T) throws { append(try encoder.boxEncodable(value)) }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        
        fatalError()
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        
        fatalError()
    }
    
    func superEncoder() -> Encoder {
        
        fatalError()
    }
    
    // MARK: - Private Methods
    
    private func append(_ data: Data) {
        
        let index = TLVTypeCode(rawValue: UInt8(count)) // current index
        let item = TLVItem(type: index, value: data)
        
        // write
        self.container.append(item) // already sorted
    }
}

// MARK: - Data Types

/// Private protocol for encoding TLV values into raw data.
internal protocol TLVRawEncodable {
    
    var tlvData: Data { get }
}

private extension TLVRawEncodable {
    
    var copyingBytes: Data {
        return withUnsafePointer(to: self, { Data(bytes: $0, count: MemoryLayout<Self>.size) })
    }
}

extension UInt8: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension UInt16: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension UInt32: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension UInt64: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension Int8: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension Int16: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension Int32: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension Int64: TLVRawEncodable {
    
    public var tlvData: Data {
        return copyingBytes
    }
}

extension Float: TLVRawEncodable {
    
    public var tlvData: Data {
        return bitPattern.copyingBytes
    }
}

extension Double: TLVRawEncodable {
    
    public var tlvData: Data {
        return bitPattern.copyingBytes
    }
}

extension Bool: TLVRawEncodable {
    
    public var tlvData: Data {
        return UInt8(self ? 1 : 0).copyingBytes
    }
}

extension String: TLVRawEncodable {
    
    public var tlvData: Data {
        return Data(self.utf8)
    }
}
