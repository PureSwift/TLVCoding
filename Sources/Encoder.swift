//
//  Encoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

public struct TLVEncoder {
    
    // MARK: - Properties
    
    /// Any contextual information set by the user for encoding.
    public var userInfo = [CodingUserInfoKey : Any]()
    
    /// Logger handler
    public var log: ((String) -> ())?
    
    // MARK: - Initialization
    
    public init() { }
    
    // MARK: - Methods
    
    public func encode <T: Encodable> (_ value: T) throws -> Data {
        
        let encoder = Encoder(userInfo: userInfo, log: log)
        try value.encode(to: encoder)
        assert(encoder.stack.containers.count == 1)
        
        guard case let .items(container) = encoder.stack.root else {
            
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) is not encoded as items."))
        }
        
        return container.data
    }
}

public extension TLVEncoder {
    
    func encode(_ items: [TLVItem]) -> Data {
        return Data(items)
    }
    
    func encode(_ items: TLVItem...) -> Data {
        return Data(items)
    }
}

@available(*, deprecated, message:  "Use TLVEncoder instance instead")
public extension TLVEncoder {
    
    static func encode(_ items: [TLVItem]) -> Data {
        return Data(items)
    }
    
    static func encode(_ items: TLVItem...) -> Data {
        return Data(items)
    }
}

internal extension TLVEncoder {
    
    final class Encoder: Swift.Encoder {
        
        // MARK: - Properties
        
        /// The path of coding keys taken to get to this point in encoding.
        fileprivate(set) var codingPath: [CodingKey]
        
        /// Any contextual information set by the user for encoding.
        let userInfo: [CodingUserInfoKey : Any]
        
        /// Logger
        let log: ((String) -> ())?
        
        private(set) var stack: Stack
        
        // MARK: - Initialization
        
        init(codingPath: [CodingKey] = [],
             userInfo: [CodingUserInfoKey : Any],
             log: ((String) -> ())?) {
            
            self.stack = Stack()
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.log = log
        }
        
        // MARK: - Encoder
        
        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            
            log?("Requested container keyed by \(type) for path \"\(codingPathString)\"")
            
            let stackContainer = ItemsContainer()
            self.stack.push(.items(stackContainer))
            
            let keyedContainer = TLVKeyedContainer<Key>(referencing: self, wrapping: stackContainer)
            
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            
            log?("Requested unkeyed container for path \"\(codingPathString)\"")
            
            let stackContainer = ItemContainer()
            self.stack.push(.item(stackContainer))
            
            return TLVUnkeyedEncodingContainer(referencing: self, wrapping: stackContainer)
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            
            log?("Requested single value container for path \"\(codingPathString)\"")
            
            let stackContainer = ItemContainer()
            self.stack.push(.item(stackContainer))
            
            return TLVSingleValueEncodingContainer(referencing: self, wrapping: stackContainer)
        }
    }
}

internal extension TLVEncoder.Encoder {
    
    /// KVC path string for current coding path.
    var codingPathString: String {
        
        return codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
    
    func typeCode <Key: CodingKey> (for key: Key, value: Any) throws -> TLVTypeCode {
        
        if let tlvCodingKey = key as? TLVCodingKey {
            
            return tlvCodingKey.code
            
        } else if let intValue = key.intValue {
            
            guard intValue <= Int(UInt8.max),
                intValue >= Int(UInt8.min) else {
                    
                    throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Coding key \(key) has an invalid integer value \(intValue)"))
            }
            
            return TLVTypeCode(rawValue: UInt8(intValue))
            
        } else if MemoryLayout<Key>.size == MemoryLayout<UInt8>.size {
            
            return TLVTypeCode(rawValue: unsafeBitCast(key, to: UInt8.self))
            
        } else {
            
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Coding key \(key) has no integer value"))
        }
    }
}

internal extension TLVEncoder.Encoder {
    
    @inline(__always)
    func box <T: TLVEncodable> (_ value: T) -> Data {
        return value.tlvData
    }
    
    func boxEncodable <T: Encodable> (_ value: T) throws -> Data {
        
        if let tlvEncodable = value as? TLVEncodable {
            return tlvEncodable.tlvData
        } else if let data = value as? Data {
            return data
        } else {
            // encode using Encodable, should push new container.
            try value.encode(to: self)
            let nestedContainer = stack.pop()
            return nestedContainer.data
        }
    }
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
        
        var items = [TLVItem]()
        
        init() { }
        
        var data: Data {
            return Data(items)
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

final class TLVKeyedContainer <K : CodingKey> : KeyedEncodingContainerProtocol {
    
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
    
    func encode(_ value: Bool, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: Int, forKey key: K) throws { try _encode(Int32(value), forKey: key) }
    
    func encode(_ value: Int8, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: Int16, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: Int32, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: Int64, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: UInt, forKey key: K) throws { try _encode(UInt32(value), forKey: key) }
    
    func encode(_ value: UInt8, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: UInt16, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: UInt32, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: UInt64, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: Float, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: Double, forKey key: K) throws { try _encode(value, forKey: key) }
    
    func encode(_ value: String, forKey key: K) throws { try _encode(value, forKey: key) }
    
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
    
    private func _encode <T: TLVEncodable> (_ value: T, forKey key: K) throws {
        
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        let data = encoder.box(value)
        try setValue(value, data: data, for: key)
    }
    
    private func setValue(_ value: Any, data: Data, for key: Key) throws {
        
        encoder.log?("Will encode value for key \(key.stringValue) at path \"\(encoder.codingPathString)\"")
        
        let type = try encoder.typeCode(for: key, value: value)
        let item = TLVItem(type: type, value: data)
        self.container.items.append(item)
    }
}

// MARK: - SingleValueEncodingContainer

final class TLVSingleValueEncodingContainer: SingleValueEncodingContainer {
    
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
    
    func encode(_ value: Double) throws { write(encoder.box(value)) }
    
    func encode(_ value: Float) throws { write(encoder.box(value)) }
    
    func encode(_ value: Int) throws { write(encoder.box(Int32(value))) }
    
    func encode(_ value: Int8) throws { write(encoder.box(value)) }
    
    func encode(_ value: Int16) throws { write(encoder.box(value)) }
    
    func encode(_ value: Int32) throws { write(encoder.box(value)) }
    
    func encode(_ value: Int64) throws { write(encoder.box(value)) }
    
    func encode(_ value: UInt) throws { write(encoder.box(UInt32(value))) }
    
    func encode(_ value: UInt8) throws { write(encoder.box(value)) }
    
    func encode(_ value: UInt16) throws { write(encoder.box(value)) }
    
    func encode(_ value: UInt32) throws { write(encoder.box(value)) }
    
    func encode(_ value: UInt64) throws { write(encoder.box(value)) }
    
    func encode <T: Encodable> (_ value: T) throws { write(try encoder.boxEncodable(value)) }
    
    // MARK: - Private Methods
    
    private func write(_ data: Data) {
        
        precondition(didWrite == false, "Data already written")
        self.container.data = data
        self.didWrite = true
    }
}

// MARK: - UnkeyedEncodingContainer

final class TLVUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    
    // MARK: - Properties
    
    /// A reference to the encoder we're writing to.
    let encoder: TLVEncoder.Encoder
    
    /// The path of coding keys taken to get to this point in encoding.
    let codingPath: [CodingKey]
    
    /// A reference to the container we're writing to.
    let container: TLVEncoder.Encoder.ItemContainer
    
    // MARK: - Initialization
    
    init(referencing encoder: TLVEncoder.Encoder,
         wrapping container: TLVEncoder.Encoder.ItemContainer) {
        
        self.encoder = encoder
        self.codingPath = encoder.codingPath
        self.container = container
    }
    
    // MARK: - Methods
    
    /// The number of elements encoded into the container.
    private(set) var count: Int = 0
    
    func encodeNil() throws {
        // do nothing
    }
    
    func encode(_ value: Bool) throws { append(encoder.box(value)) }
    
    func encode(_ value: String) throws { append(encoder.box(value)) }
    
    func encode(_ value: Double) throws { append(encoder.box(value)) }
    
    func encode(_ value: Float) throws { append(encoder.box(value)) }
    
    func encode(_ value: Int) throws { append(encoder.box(Int32(value))) }
    
    func encode(_ value: Int8) throws { append(encoder.box(value)) }
    
    func encode(_ value: Int16) throws { append(encoder.box(value)) }
    
    func encode(_ value: Int32) throws { append(encoder.box(value)) }
    
    func encode(_ value: Int64) throws { append(encoder.box(value)) }
    
    func encode(_ value: UInt) throws { append(encoder.box(UInt32(value))) }
    
    func encode(_ value: UInt8) throws { append(encoder.box(value)) }
    
    func encode(_ value: UInt16) throws { append(encoder.box(value)) }
    
    func encode(_ value: UInt32) throws { append(encoder.box(value)) }
    
    func encode(_ value: UInt64) throws { append(encoder.box(value)) }
    
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
        
        self.container.data += data
        self.count += 1
    }
}

// MARK: - Data Types

private extension TLVEncodable {
    
    var copyingBytes: Data {
        
        var copy = self
        return withUnsafePointer(to: &copy, { Data(bytes: $0, count: MemoryLayout<Self>.size) })
    }
}

extension UInt8: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension UInt16: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension UInt32: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension UInt64: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Int8: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Int16: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Int32: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Int64: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Float: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Double: TLVEncodable {
    
    public var tlvData: Data {
        
        return copyingBytes
    }
}

extension Bool: TLVEncodable {
    
    public var tlvData: Data {
        
        return UInt8(self ? 1 : 0).copyingBytes
    }
}

extension String: TLVEncodable {
    
    public var tlvData: Data {
        
        return Data(self.utf8)
    }
}
