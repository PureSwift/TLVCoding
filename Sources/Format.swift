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

/// TLV Date Encoding Format
public enum TLVDateFormat: Equatable, Hashable {
    
    /// The strategy that encodes dates in terms of seconds since midnight UTC on January 1, 1970.
    case secondsSince1970
    
    /// The strategy that encodes dates in terms of milliseconds since midnight UTC on January 1, 1970.
    case millisecondsSince1970
    
    /// The strategy that formats dates according to the ISO 8601 and RFC 3339 standards.
    case iso8601
    
    /// The strategy that defers formatting settings to a supplied date formatter.
    case formatted(DateFormatter)
    
    /// The strategy that formats custom dates by calling a user-defined function.
    case custom((Date, Encoder) -> Void)
}

internal struct TLVOptions {
    
    let numericFormat: TLVNumericFormat
    
    let uuidFormat: TLVUUIDFormat
    
    let dateFormat: TLVDateFormat
}
