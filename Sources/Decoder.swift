//
//  Decoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

struct TLVDecoder {
    
    static func decode(data: Data, from types: [TLVDecodable.Type]) throws -> [TLVDecodable] {
        
        var offset = 0
        
        var decodables = [TLVDecodable]()
        
        while offset < data.count {
            
            // validate size
            guard data.count >= 3
                else { throw DecodingError.invalidSize(data.count, context: DecodingContext(offset: offset)) }
            
            // get type
            let typeByte = data[offset] // 0
            offset += 1
            
            guard let type = types.first(where: { $0.typeCode.rawValue == typeByte })
                else { throw DecodingError.invalidType(typeByte, context: DecodingContext(offset: offset)) }
            
            let length = Int(data[offset]) // 1
            offset += 1
            
            // get value
            let valueData = Data(data[offset ..< offset + length])
            
            guard let value = type.init(valueData: valueData)
                else { throw DecodingError.invalidValue(valueData, context: DecodingContext(offset: offset)) }
            
            // append result
            decodables.append(value)
            
            // adjust offset for next value
            offset += length
        }
        
        return decodables
    }
}

// MARK: - Supporting Types

extension TLVDecoder {
    
    struct DecodingContext {
        
        let offset: Int
    }
    
    enum DecodingError: Swift.Error {
        
        case invalidSize(Int, context: DecodingContext)
        case invalidType(UInt8, context: DecodingContext)
        case invalidValue(Data, context: DecodingContext)
        case decodableMismatch([TLVDecodable])
    }
}


// MARK: - Coder Convenience Extensions

extension TLVDecoder {
    
    static func decode <Decodable: TLVDecodable> (data: Data, from type: Decodable.Type) throws -> Decodable {
        
        let decodables = try decode(data: data, from: [type])
        
        guard decodables.count == 1,
            let decodable = decodables[0] as? Decodable
            else { throw DecodingError.decodableMismatch(decodables) }
        
        return decodable
    }
    
    static func decode <T1: TLVDecodable, T2: TLVDecodable>
        (data: Data, from types: (T1.Type, T2.Type)) throws -> (T1, T2) {
        
        let decodables = try decode(data: data, from: [types.0, types.1])
        
        guard decodables.count == 2,
            let decodable1 = decodables[0] as? T1,
            let decodable2 = decodables[1] as? T2
            else { throw DecodingError.decodableMismatch(decodables) }
        
        return (decodable1, decodable2)
    }
    
    static func decode <T1: TLVDecodable, T2: TLVDecodable, T3: TLVDecodable>
        (data: Data, from types: (T1.Type, T2.Type, T3.Type)) throws -> (T1, T2, T3) {
        
        let decodables = try decode(data: data, from: [types.0, types.1, types.2])
        
        guard decodables.count == 3,
            let decodable1 = decodables[0] as? T1,
            let decodable2 = decodables[1] as? T2,
            let decodable3 = decodables[2] as? T3
            else { throw DecodingError.decodableMismatch(decodables) }
        
        return (decodable1, decodable2, decodable3)
    }
    
    static func decode <T1: TLVDecodable, T2: TLVDecodable, T3: TLVDecodable, T4: TLVDecodable>
        (data: Data, from types: (T1.Type, T2.Type, T3.Type, T4.Type)) throws -> (T1, T2, T3, T4) {
        
        let decodables = try decode(data: data, from: [types.0, types.1, types.2, types.3])
        
        guard decodables.count == 4,
            let decodable1 = decodables[0] as? T1,
            let decodable2 = decodables[1] as? T2,
            let decodable3 = decodables[2] as? T3,
            let decodable4 = decodables[3] as? T4
            else { throw DecodingError.decodableMismatch(decodables) }
        
        return (decodable1, decodable2, decodable3, decodable4)
    }
    
    static func decode <T1: TLVDecodable, T2: TLVDecodable, T3: TLVDecodable, T4: TLVDecodable, T5: TLVDecodable>
        (data: Data, from types: (T1.Type, T2.Type, T3.Type, T4.Type, T5.Type)) throws -> (T1, T2, T3, T4, T5) {
        
        let decodables = try decode(data: data, from: [types.0, types.1, types.2, types.3, types.4])
        
        guard decodables.count == 5,
            let decodable1 = decodables[0] as? T1,
            let decodable2 = decodables[1] as? T2,
            let decodable3 = decodables[2] as? T3,
            let decodable4 = decodables[3] as? T4,
            let decodable5 = decodables[4] as? T5
            else { throw DecodingError.decodableMismatch(decodables) }
        
        return (decodable1, decodable2, decodable3, decodable4, decodable5)
    }
    
    static func decode <T1: TLVDecodable, T2: TLVDecodable, T3: TLVDecodable, T4: TLVDecodable, T5: TLVDecodable, T6: TLVDecodable>
        (data: Data, from types: (T1.Type, T2.Type, T3.Type, T4.Type, T5.Type, T6.Type)) throws -> (T1, T2, T3, T4, T5, T6) {
        
        let decodables = try decode(data: data, from: [types.0, types.1, types.2, types.3, types.4, types.5])
        
        guard decodables.count == 6,
            let decodable1 = decodables[0] as? T1,
            let decodable2 = decodables[1] as? T2,
            let decodable3 = decodables[2] as? T3,
            let decodable4 = decodables[3] as? T4,
            let decodable5 = decodables[4] as? T5,
            let decodable6 = decodables[5] as? T6
            else { throw DecodingError.decodableMismatch(decodables) }
        
        return (decodable1, decodable2, decodable3, decodable4, decodable5, decodable6)
    }
    
    static func decodeOptional <T1: TLVDecodable, T2: TLVDecodable, T3: TLVDecodable, T4: TLVDecodable, T5: TLVDecodable, T6: TLVDecodable>
        (data: Data, from types: (T1.Type, T2.Type, T3.Type, T4.Type, T5.Type, T6.Type)) throws -> (T1?, T2?, T3?, T4?, T5?, T6?) {
        
        let decodables = try decode(data: data, from: [types.0, types.1, types.2, types.3, types.4, types.5])
            .sorted(by: { type(of: $0).typeCode.rawValue < type(of: $1).typeCode.rawValue })
        
        return (decodables.count > 0 ? decodables[0] as? T1 : nil,
                decodables.count > 1 ? decodables[1] as? T2 : nil,
                decodables.count > 2 ? decodables[2] as? T3 : nil,
                decodables.count > 3 ? decodables[3] as? T4 : nil,
                decodables.count > 4 ? decodables[4] as? T5 : nil,
                decodables.count > 5 ? decodables[5] as? T6 : nil)
    }
}
