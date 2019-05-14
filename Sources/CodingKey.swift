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

public extension TLVCodingKey where Self: RawRepresentable, Self.RawValue == TLVTypeCode.RawValue {
    
    init?(code: TLVTypeCode) {
        self.init(rawValue: code.rawValue)
    }
    
    var code: TLVTypeCode {
        return TLVTypeCode(rawValue: rawValue)
    }
}

#if swift(>=4.2)
public extension TLVCodingKey where Self: CaseIterable, Self: RawRepresentable, Self.RawValue == TLVTypeCode.RawValue {
    
    init?(stringValue: String) {
        
        guard let value = Self.allCases.first(where: { $0.stringValue == stringValue })
            else { return nil }
        
        self = value
    }
}
#endif

internal extension TLVTypeCode {
    
    init? <K: CodingKey> (codingKey: K) {
        
        if let tlvCodingKey = codingKey as? TLVCodingKey {
            
            self = tlvCodingKey.code
            
        } else if let intValue = codingKey.intValue {
            
            guard intValue <= Int(UInt8.max),
                intValue >= Int(UInt8.min)
                else { return nil }
            
            self.init(rawValue: UInt8(intValue))
            
        } else if MemoryLayout<K>.size == MemoryLayout<UInt8>.size,
            Mirror(reflecting: codingKey).displayStyle == .enum {
            
            self.init(rawValue: unsafeBitCast(codingKey, to: UInt8.self))
            
        } else {
            
            return nil
        }
    }
}

internal extension Sequence where Element == CodingKey {
    
    /// KVC path string for current coding path.
    var path: String {
        return reduce("", { $0 + "\($0.isEmpty ? "" : ".")" + $1.stringValue })
    }
}

internal extension CodingKey {
    
    static var sanitizedName: String {
        
        let rawName = String(reflecting: self)
        #if swift(>=5.0)
        var elements = rawName.split(separator: ".")
        #else
        var elements = rawName.components(separatedBy: ".")
        #endif
        guard elements.count > 2
            else { return rawName }
        elements.removeFirst()
        #if swift(>=5.0)
        elements.removeAll { $0.contains("(unknown context") }
        #else
        while let index = elements.index(where: { $0.contains("(unknown context") }) {
            elements.remove(at: index)
        }
        #endif
        return elements.reduce("", { $0 + ($0.isEmpty ? "" : ".") + $1 })
    }
}
