//
//  NumericFormat.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/13/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

import Foundation

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
public enum TLVDateFormat: Equatable {
    
    /// Encodes dates in terms of seconds since midnight UTC on January 1, 1970.
    case secondsSince1970
    
    /// Encodes dates in terms of milliseconds since midnight UTC on January 1, 1970.
    case millisecondsSince1970
    
    /// Formats dates according to the ISO 8601 and RFC 3339 standards.
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    case iso8601
    
    /// Defers formatting settings to a supplied date formatter.
    case formatted(DateFormatter)
}

internal struct TLVOptions {
    
    let numericFormat: TLVNumericFormat
    
    let uuidFormat: TLVUUIDFormat
    
    let dateFormat: TLVDateFormat
}

// MARK: - Formatters

internal extension TLVDateFormat {
    
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}

internal protocol DateFormatterProtocol: class {
    
    func string(from date: Date) -> String
    
    func date(from string: String) -> Date?
}

extension DateFormatter: DateFormatterProtocol { }

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension ISO8601DateFormatter: DateFormatterProtocol { }
