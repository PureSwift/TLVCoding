//
//  NumericFormat.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/13/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

/// TLV Numeric Encoding Format
public enum TLVNumericFormat: Equatable, Hashable {
    
    case bigEndian
    case littleEndian
}

/// TLV UUID Encoding Format
public enum TLVUUIDFormat: Equatable, Hashable {
    
    case bytes
    case string
}

internal struct TLVOptions {
    
    let numericFormat: TLVNumericFormat
    
    let uuidFormat: TLVUUIDFormat
}
