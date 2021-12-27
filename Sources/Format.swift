//
//  NumericFormat.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/13/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

import Foundation

/// The output formatting options that determine the readability, size, and element order of an encoded TLV object.
public struct TLVOutputFormatting: Equatable, Hashable {
    
    /// The output formatting option that sorts keys in numerical order.
    public var sortedKeys: Bool
}

public extension TLVOutputFormatting {
    
    /// The default TLV output formatting options.
    static var `default`: TLVOutputFormatting {
        return .init(sortedKeys: true)
    }
}

/// TLV number formatting (endianness).
public enum TLVNumericFormatting: Equatable, Hashable {
    
    case littleEndian
    case bigEndian
}

public extension TLVNumericFormatting {
    
    /// The default TLV endianness for binary representation of numbers.
    static var `default`: TLVNumericFormatting {
        return .littleEndian
    }
}

@available(*, deprecated, message: "Renamed to TLVNumericFormatting")
public typealias TLVNumericFormat = TLVNumericFormatting

/// TLV `UUID` Encoding Format
public enum TLVUUIDFormatting: Equatable, Hashable {
    
    case bytes
    case string
}

public extension TLVUUIDFormatting {
    
    /// The default TLV `UUID` format.
    static var `default`: TLVUUIDFormatting {
        return .bytes
    }
}

@available(*, deprecated, message: "Renamed to TLVUUIDFormatting")
public typealias TLVUUIDFormat = TLVUUIDFormatting

/// TLV `Date` Encoding Format
public enum TLVDateFormatting: Equatable {
    
    /// Encodes dates in terms of seconds since midnight UTC on January 1, 1970.
    case secondsSince1970
    
    /// Encodes dates in terms of milliseconds since midnight UTC on January 1, 1970.
    case millisecondsSince1970
    
    #if !os(WASI)
    /// Formats dates according to the ISO 8601 and RFC 3339 standards.
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    case iso8601
    
    /// Defers formatting settings to a supplied date formatter.
    case formatted(DateFormatter)
    #endif
}

public extension TLVDateFormatting {
    
    /// The default TLV `Date` format.
    static var `default`: TLVDateFormatting {
        return .secondsSince1970
    }
}

@available(*, deprecated, message: "Renamed to TLVDateFormatting")
public typealias TLVDateFormat = TLVDateFormatting

// MARK: - Formatters

#if !os(WASI)
internal protocol DateFormatterProtocol: AnyObject {
    
    func string(from date: Date) -> String
    
    func date(from string: String) -> Date?
}

internal extension TLVDateFormatting {
    
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        return formatter
    }()
}

extension DateFormatter: DateFormatterProtocol { }

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension ISO8601DateFormatter: DateFormatterProtocol { }
#endif
