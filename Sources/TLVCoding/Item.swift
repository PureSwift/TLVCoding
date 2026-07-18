//
//  Item.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

#if canImport(Foundation) && !hasFeature(Embedded)
import Foundation
#endif

/**
 TLV8 (Type-length-value) Item
 */
public struct TLVItem: Equatable, Hashable, Sendable {

    /// TLV code
    public var type: TLVTypeCode

    /// TLV data payload
    public var value: Data

    public init(type: TLVTypeCode, value: Data) {
        assert(value.count <= UInt8.max)
        self.type = type
        self.value = value
    }
}

public extension TLVItem {

    /// Length of the value payload.
    var length: UInt8 {
        UInt8(value.count)
    }

    /// Data representation (type byte, length byte, value payload).
    var data: Data {
        var data = Data()
        data.reserveCapacity(dataLength)
        append(to: &data)
        return data
    }

    /// Length of the item when encoded into data.
    internal var dataLength: Int {
        2 + value.count
    }

    internal func append(to data: inout Data) {
        data.append(type.rawValue)
        data.append(length)
        data.append(contentsOf: value)
    }
}
