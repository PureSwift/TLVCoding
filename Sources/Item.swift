//
//  Item.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

import Foundation

/**
 TLV8 (Type-length-value) Item
 */
public struct TLVItem: Equatable, Hashable {
    
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
    
    var length: UInt8 {
        return UInt8(value.count)
    }
}

public extension TLVItem {
    
    var data: Data {
        return Data(self)
    }
}

// MARK: - DataConvertible

extension TLVItem: DataConvertible {
    
    var dataLength: Int {
        
        return 1 + 1 + value.count
    }
    
    static func += <T: DataContainer> (data: inout T, value: TLVItem) {
        
        data += value.type.rawValue
        data += value.length
        data += value.value
    }
}

