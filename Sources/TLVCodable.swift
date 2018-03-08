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

#if swift(>=3.2)

public extension TLVDecodable where Self: RawRepresentable, Self.RawValue: RawRepresentable, Self.RawValue.RawValue == UInt8 {
    
    public init?(valueData: Foundation.Data) {
        
        guard valueData.count == 1
            else { return nil }
        
        let valueByte = valueData[0]
        
        guard let rawValue = RawValue.init(rawValue: valueByte)
            else { return nil }
        
        self.init(rawValue: rawValue)
    }
}

public extension TLVEncodable where Self: RawRepresentable, Self.RawValue: RawRepresentable, Self.RawValue.RawValue == UInt8 {
    
    public var valueData: Foundation.Data {
        
        let byte = rawValue.rawValue
        
        return Data([byte])
    }
}

public extension TLVDecodable where Self: RawRepresentable, Self.RawValue == String {
    
    public init?(valueData: Foundation.Data) {
        
        guard let string = String(data: valueData, encoding: .utf8)
            else { return nil }
        
        self.init(rawValue: string)
    }
}

public extension TLVEncodable where Self: RawRepresentable, Self.RawValue == String {
    
    public var valueData: Foundation.Data {
                
        guard let data = self.rawValue.data(using: .utf8)
            else { fatalError("Could not encode string") }
        
        return data
    }
}

#endif

