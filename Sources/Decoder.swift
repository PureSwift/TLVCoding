//
//  Decoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

public struct TLVDecoder {
    
    
}


internal extension TLVDecoder {
    
    static func decode(_ data: Data) throws -> [TLVItem] {
        
        var offset = 0
        var items = [TLVItem]()
        
        while offset < data.count {
            
            // validate size
            guard data.count >= 3
                else { throw DecodingError.invalidSize(data.count, context: DecodingContext(offset: offset)) }
            
            // get type
            let typeByte = data[offset] // 0
            offset += 1
            
            let length = Int(data[offset]) // 1
            offset += 1
            
            // get value
            let valueData = Data(data[offset ..< offset + length])
            
            let item = TLVItem(type: TLVTypeCode(rawValue: typeByte), value: valueData)
            
            // append result
            items.append(item)
            
            // adjust offset for next value
            offset += length
        }
        
        return items
    }
}

// MARK: - Supporting Types

public extension TLVDecoder {
    
    struct DecodingContext {
        
        public let offset: Int
    }
    
    enum DecodingError: Swift.Error {
        
        case invalidSize(Int, context: DecodingContext)
        case invalidType(UInt8, context: DecodingContext)
        case invalidValue(Data, context: DecodingContext)
        case decodableMismatch([TLVDecodable])
    }
}
