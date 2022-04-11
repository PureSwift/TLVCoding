//
//  DataConvertible.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

import Foundation

/// Can be converted into data.
internal protocol DataConvertible {
    
    /// Append data representation into buffer.
    static func += <T: DataContainer> (data: inout T, value: Self)
    
    /// Length of value when encoded into data.
    var dataLength: Int { get }
}

extension Data {
    
    /// Initialize data with contents of value.
    @inline(__always)
    init <T: DataConvertible> (_ value: T) {
        self.init(capacity: value.dataLength)
        self += value
    }
    
    init <T: Sequence> (_ sequence: T) where T.Element: DataConvertible {
        
        let dataLength = sequence.reduce(0, { $0 + $1.dataLength })
        self.init(capacity: dataLength)
        sequence.forEach { self += $0 }
    }
}

// MARK: - UnsafeDataConvertible

/// Internal Data casting protocol
internal protocol UnsafeDataConvertible: DataConvertible { }

extension UnsafeDataConvertible {
    
    var dataLength: Int {
        return MemoryLayout<Self>.size
    }
    
    /// Append data representation into buffer.
    static func += <T: DataContainer> (data: inout T, value: Self) {
        var value = value
        withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Self>.size) {
                data.append($0, count: MemoryLayout<Self>.size)
            }
        }
    }
}

extension UInt16: UnsafeDataConvertible { }
extension UInt32: UnsafeDataConvertible { }
extension UInt64: UnsafeDataConvertible { }
extension UUID: UnsafeDataConvertible { }

// MARK: - DataContainer

/// Data container type.
internal protocol DataContainer: RandomAccessCollection where Self.Index == Int {
    
    subscript(index: Int) -> UInt8 { get }
    
    mutating func append(_ newElement: UInt8)
    
    mutating func append(_ pointer: UnsafePointer<UInt8>, count: Int)
    
    mutating func append <C: Collection> (contentsOf bytes: C) where C.Element == UInt8
    
    static func += (lhs: inout Self, rhs: UInt8)
    
    static func += <C: Collection> (lhs: inout Self, rhs: C) where C.Element == UInt8
}

extension DataContainer {
    
    mutating func append <T: DataConvertible> (_ value: T) {
        self += value
    }
}

extension Data: DataContainer {
    
    static func += (lhs: inout Data, rhs: UInt8) {
        lhs.append(rhs)
    }
}
