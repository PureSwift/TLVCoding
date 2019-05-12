//
//  CodingKey.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

public protocol TLVCodingKey: CodingKey {
    
    init?(code: TLVTypeCode)
    
    var code: TLVTypeCode { get }
}

public extension TLVCodingKey {
    
    init?(intValue: Int) {
        
        guard intValue <= Int(UInt8.max),
            intValue >= Int(UInt8.min)
            else { return nil }
        
        self.init(code: TLVTypeCode(rawValue: UInt8(intValue)))
    }
    
    var intValue: Int? {
        
        return Int(code.rawValue)
    }
}

internal extension TLVTypeCode {
    
    init? <K: CodingKey> (codingKey: K) {
        
        if let tlvCodingKey = codingKey as? TLVCodingKey {
            
            self = tlvCodingKey.code
            
        } else if let intValue = codingKey.intValue {
            
            guard intValue <= Int(UInt8.max),
                intValue >= Int(UInt8.min)
                else { return nil }
            
            self.init(rawValue: UInt8(intValue))
            
        } else if MemoryLayout<K>.size == MemoryLayout<UInt8>.size {
            
            self.init(rawValue: unsafeBitCast(codingKey, to: UInt8.self))
            
        } else {
            
            return nil
        }
    }
}
