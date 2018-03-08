//
//  TLVCoding.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Type-Length-Value Codable
public typealias TLVCodable = TLVEncodable & TLVDecodable

/// TLV Decodable type
public protocol TLVDecodable {
    
    static var typeCode: TLVTypeCode { get }
    
    init?(valueData: Foundation.Data)
}

public protocol TLVEncodable {
    
    static var typeCode: TLVTypeCode { get }
    
    var valueData: Foundation.Data { get }
}

/// TLV Type Code header
public protocol TLVTypeCode {
    
    init?(rawValue: UInt8)
    
    var rawValue: UInt8 { get }
}

// MARK: - Codable Implementations

public extension TLVDecodable where Self: RawRepresentable, Self.RawValue: RawRepresentable, Self.RawValue.RawValue: Integer {
    
    public init?(valueData: Foundation.Data) {
        
        typealias IntegerType = Self.RawValue.RawValue
        
        assert(MemoryLayout<IntegerType>.size == 1)
        
        guard valueData.count == 1
            else { return nil }
        
        let valueByte = valueData[0]
        
        guard let rawValue = RawValue.init(rawValue: numericCast(valueByte) as IntegerType)
            else { return nil }
        
        self.init(rawValue: rawValue)
    }
}

public extension TLVEncodable where Self: RawRepresentable, Self.RawValue: RawRepresentable, Self.RawValue.RawValue: Integer {
    
    public var valueData: Foundation.Data {
        
        typealias IntegerType = Self.RawValue.RawValue
        
        assert(MemoryLayout<IntegerType>.size == 1)
        
        let byte = numericCast(rawValue.rawValue) as UInt8
        
        return Data([byte])
    }
}

public extension TLVDecodable where Self: RawRepresentable, Self.RawValue: StringProtocol {
    
    public init?(valueData: Foundation.Data) {
        
        guard let string = String(data: valueData, encoding: .utf8) as? Self.RawValue
            else { return nil }
        
        self.init(rawValue: string)
    }
}

public extension TLVEncodable where Self: RawRepresentable, Self.RawValue: StringProtocol {
    
    public var valueData: Foundation.Data {
                
        guard let data = (self.rawValue as? String)?.data(using: .utf8)
            else { fatalError("Could not encode string") }
        
        return data
    }
}
