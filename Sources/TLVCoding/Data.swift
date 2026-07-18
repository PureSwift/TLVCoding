//
//  Data.swift
//  TLVCoding
//
//  Minimal Foundation-free `Data` for platforms without Foundation
//  (e.g. Embedded Swift). Not API-complete — TLV round-tripping only.
//

#if (!canImport(FoundationEssentials) && !canImport(Foundation)) || hasFeature(Embedded)

public struct Data: Sendable {

    internal var bytes: [UInt8]

    public init() {
        self.bytes = []
    }

    public init<S: Sequence>(_ elements: S) where S.Element == UInt8 {
        self.bytes = Array(elements)
    }

    public init(repeating byte: UInt8, count: Int) {
        self.bytes = Array(repeating: byte, count: count)
    }

    public mutating func reserveCapacity(_ capacity: Int) {
        bytes.reserveCapacity(capacity)
    }
}

// MARK: - Collection

extension Data: RandomAccessCollection, MutableCollection {

    public typealias Element = UInt8
    public typealias Index = Int

    public var startIndex: Int { bytes.startIndex }
    public var endIndex: Int { bytes.endIndex }

    public subscript(position: Int) -> UInt8 {
        get { bytes[position] }
        set { bytes[position] = newValue }
    }

    public func index(after i: Int) -> Int { bytes.index(after: i) }
    public func index(before i: Int) -> Int { bytes.index(before: i) }
}

extension Data {

    public mutating func append(_ byte: UInt8) {
        bytes.append(byte)
    }

    public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == UInt8 {
        bytes.append(contentsOf: newElements)
    }
}

// MARK: - Equatable, Hashable

extension Data: Equatable, Hashable {

    public static func == (lhs: Data, rhs: Data) -> Bool {
        lhs.bytes == rhs.bytes
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }
}

#endif
