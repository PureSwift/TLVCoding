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

public extension TLVCodingKey where Self: RawRepresentable, RawValue == TLVTypeCode.RawValue {
    
    init?(code: TLVTypeCode) {
        self.init(rawValue: code.rawValue)
    }
    
    var code: TLVTypeCode {
        return TLVTypeCode(rawValue: rawValue)
    }
}

public extension TLVCodingKey where Self: CaseIterable, Self: RawRepresentable, RawValue == TLVTypeCode.RawValue {
    
    init?(stringValue: String) {
        
        guard let value = Self.allCases.first(where: { $0.stringValue == stringValue })
            else { return nil }
        
        self = value
    }
}
