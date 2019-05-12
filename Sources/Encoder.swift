//
//  Encoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

public struct TLVEncoder {
    
    public func encode <T: Encodable> (_ encodable: T) throws -> Data {
        
        
    }
}

public extension TLVEncoder {
    
    public enum EncodingError: Error {
        
        public typealias Context = Swift.EncodingError.Context
        
        /// Invalid coding key provided.
        case invalidKey(CodingKey, Context)
    }
}

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
        private(set) var codingPath: [CodingKey]
        
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
            
            let stackContainer = AttributesContainer()
            self.stack.push(.attributes(stackContainer))
            
            let keyedContainer = KeyedContainer<Key>(referencing: self, wrapping: stackContainer)
            
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            
            log?("Requested unkeyed container for path \"\(codingPathString)\"")
            
            let stackContainer = AttributesContainer()
            self.stack.push(.attributes(stackContainer))
            
            return AttributesUnkeyedEncodingContainer(referencing: self, wrapping: stackContainer)
        }
        
        func singleValueContainer() -> SingleValueEncodingContainer {
            
            log?("Requested single value container for path \"\(codingPathString)\"")
            
            let stackContainer = AttributeContainer()
            self.stack.push(.attribute(stackContainer))
            
            return AttributeSingleValueEncodingContainer(referencing: self, wrapping: stackContainer)
        }
    }
}

internal extension TLVEncoder.Encoder {
    
    /// KVC path string for current coding path.
    var codingPathString: String {
        
        return codingPath.reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
    
    func typeCode <Key: CodingKey> (for key: Key) throws -> TLVTypeCode {
        
        if let tlvCodingKey = key as? TLVCodingKey {
            
            return tlvCodingKey.code
            
        } else if let intValue = key.intValue {
            
            guard intValue <= Int(UInt8.max),
                intValue >= Int(UInt8.min) else {
                    
                    throw NetlinkAttributeEncoder.EncodingError.invalidKey(key, EncodingError.Context(codingPath: codingPath, debugDescription: "\(key) has an invalid integer value \(intValue)"))
            }
            
            return TLVTypeCode(rawValue: UInt8(intValue))
            
        } else if MemoryLayout<Key>.size == MemoryLayout<UInt8>.size {
            
            return TLVTypeCode(rawValue: unsafeBitCast(codingKey, to: UInt8.self))
            
        } else {
            
            throw TLVEncoder.EncodingError.invalidKey(key, EncodingError.Context(codingPath: codingPath, debugDescription: "\(key) has no integer value"))
        }
    }
}

// MARK: - Stack

internal extension TLVEncoder.Encoder {
    
    internal struct Stack {
        
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

