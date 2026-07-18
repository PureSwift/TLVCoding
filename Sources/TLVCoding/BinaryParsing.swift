//
//  BinaryParsing.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/18/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if canImport(BinaryParsing) && !hasFeature(Embedded)
import BinaryParsing

// MARK: - TLVTypeCode

extension TLVTypeCode: ExpressibleByParsing {

    /// Parse a type code from a single byte.
    public init(parsing input: inout ParserSpan) throws(ThrownParsingError) {
        self.init(rawValue: try UInt8(parsing: &input))
    }
}

// MARK: - TLVItem

extension TLVItem: ExpressibleByParsing {

    /// Parse a single TLV8 item (type byte, length byte, value payload).
    public init(parsing input: inout ParserSpan) throws(ThrownParsingError) {
        let type = try TLVTypeCode(parsing: &input)
        let length = try Int(parsing: &input, storedAs: UInt8.self)
        let value = try Data(parsing: &input, byteCount: length)
        self.init(type: type, value: value)
    }
}

// MARK: - TLVContainer

extension TLVContainer: ExpressibleByParsing {

    /// Parse a container of TLV8 items, consuming the entire input.
    public init(parsing input: inout ParserSpan) throws(ThrownParsingError) {
        var items = [TLVItem]()
        while !input.isEmpty {
            items.append(try TLVItem(parsing: &input))
        }
        self.init(items: items)
    }
}

#endif
