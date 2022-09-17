//
//  TLVCodingTests.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
import XCTest
@testable import TLVCoding

final class TLVCodingTests: XCTestCase {
    
    static let allTests = [
        ("testCodable", testCodable),
        ("testCodingKeys", testCodingKeys),
        ("testUUID", testUUID),
        ("testDate", testDate),
        ("testDateSecondsSince1970", testDateSecondsSince1970),
        ("testOutputFormatting", testOutputFormatting)
    ]
    
    func testCodable() {
        
        compare(
            [
                UInt8(0xAA),
                UInt8(0xBB),
                UInt8(0xCC),
            ],
            Data([
                0,1,0xAA,
                1,1,0xBB,
                2,1,0xCC
            ])
        )
        
        compare(Person(gender: .male, name: "Coleman"),
            Data([0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110]))
        
        compare(Person(gender: .male, name: "Coleman"),
             Data([0, 1]),
             shouldFail: true
        )
        
        compare(Person(gender: .male, name: "Coleman"),
             Data([0, 2, 0]),
             shouldFail: true
        )
        
        compare(Person(gender: .male, name: ""),
             Data([0, 1, 0, 1, 0]))
        
        compare(ProvisioningState(state: .idle, result: .notAvailible),
            Data([0x01, 0x01, 0x00, 0x02, 0x01, 0x00]))
        
        compare(ProvisioningState(state: .provisioning, result: .notAvailible),
            Data([0x01, 0x01, 0x01, 0x02, 0x01, 0x00]))
        
        compare(Numeric(
            boolean: true,
            int: -10,
            uint: 10,
            float: 1.1234,
            double: 10.9999,
            int8: .max,
            int16: -200,
            int32: -2000,
            int64: -20_000,
            uint8: .max,
            uint16: 300,
            uint32: 3000,
            uint64: 30_000),
             Data([0, 1, 1, 1, 4, 246, 255, 255, 255, 2, 4, 10, 0, 0, 0, 3, 4, 146, 203, 143, 63, 4, 8, 114, 138, 142, 228, 242, 255, 37, 64, 5, 1, 127, 6, 2, 56, 255, 7, 4, 48, 248, 255, 255, 8, 8, 224, 177, 255, 255, 255, 255, 255, 255, 9, 1, 255, 10, 2, 44, 1, 11, 4, 184, 11, 0, 0, 12, 8, 48, 117, 0, 0, 0, 0, 0, 0]))
        
        compare(
            Version(major: 1, minor: 2, patch: 3),
            Data([0x01, 0x02, 0x03])
        )
        
        compare(
            CustomEncodable(
                data: nil,
                uuid: nil,
                number: nil,
                date: nil
            ),
            Data([])
        )
        
        compare(
            CustomEncodable(
                data: Data(),
                uuid: nil,
                number: nil,
                date: nil
            ),
            Data([0, 0])
        )
        
        compare(
            CustomEncodable(
                data: Data([0x00, 0x01]),
                uuid: nil,
                number: nil,
                date: nil
            ),
            Data([0, 2, 0x00, 0x01])
        )
        
        compare(
            Profile(
                person: Person(
                    gender: .male,
                    name: "Coleman"
                ), friends: [
                    Person(
                        gender: .male,
                        name: "Coleman"
                    )
                ],
                userInfo: nil
            ),
            Data([0, 12, 0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110,
                  1, 14, 0, 12, 0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110])
        )
        
        compare(
            Profile(
                person: Person(
                    gender: .male,
                    name: "Coleman"
            ), friends: [
                Person(
                    gender: .female,
                    name: "Gina"
                ),
                Person(
                    gender: .female,
                    name: "Jossy"
                ),Person(
                    gender: .male,
                    name: "Jorge"
                )
                ],
               userInfo: nil
            ),
            Data([0, 12,
                    0, 1,
                        0,
                    1, 7,
                        67, 111, 108, 101, 109, 97, 110,
                  1, 35,
                    0, 9,
                        0, 1,
                            1,
                        1, 4,
                            71, 105, 110, 97,
                    1, 10,
                        0, 1,
                            1,
                        1, 5,
                            74, 111, 115, 115, 121,
                    2, 10,
                        0, 1,
                            0,
                        1, 5,
                            74, 111, 114, 103, 101
                ])
        )
        
        compare(
            Binary(
                data: Data([0x01, 0x02, 0x03, 0x04]),
                value: .one
            ),
            Data([0, 4, 1, 2, 3, 4, 1, 2, 1, 0])
        )
        
        compare(
            PrimitiveArray(
                strings: ["1", "two", "three", ""],
                integers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            ),
            Data([0, 17, 0, 1, 49, 1, 3, 116, 119, 111, 2, 5, 116, 104, 114, 101, 101, 3, 0, 1, 60, 0, 4, 1, 0, 0, 0, 1, 4, 2, 0, 0, 0, 2, 4, 3, 0, 0, 0, 3, 4, 4, 0, 0, 0, 4, 4, 5, 0, 0, 0, 5, 4, 6, 0, 0, 0, 6, 4, 7, 0, 0, 0, 7, 4, 8, 0, 0, 0, 8, 4, 9, 0, 0, 0, 9, 4, 10, 0, 0, 0])
        )
        
        compare(
            DeviceInformation(
                identifier: UUID(uuidString: "B83DD6F4-A429-41B3-945A-3E0EE5915CA1")!,
                buildVersion: DeviceInformation.BuildVersion(rawValue: 1),
                version: Version(major: 1, minor: 2, patch: 3),
                status: .provisioned,
                features: .all
            ),
            Data([0, 16, 184, 61, 214, 244, 164, 41, 65, 179, 148, 90, 62, 14, 229, 145, 92, 161, 1, 8, 1, 0, 0, 0, 0, 0, 0, 0, 2, 3, 1, 2, 3, 3, 1, 2, 4, 1, 7])
        )
        
        compare(
            CryptoRequest(secret: CryptoData()),
            Data([0, 32, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255])
        )
        
        compare(
            CustomEncodableArray(elements: [
                .value(
                    CustomEncodableArray.Value(
                        identifier: UUID(uuidString: "B83DD6F4-A429-41B3-945A-3E0EE5915CA1")!,
                        name: "Value 1"
                    )
                ),
                .value(
                    CustomEncodableArray.Value(
                        identifier: UUID(uuidString: "B83DD6F4-A429-41B3-945A-3E0EE5915CA2")!,
                        name: "Value 2"
                    )
                ),
                .pendingValue(
                    CustomEncodableArray.PendingValue(
                        identifier: UUID(uuidString: "B83DD6F4-A429-41B3-945A-3E0EE5915CA3")!,
                        name: "Pending Value 1",
                        expiration: Date.distantFuture
                    )
                )
                ]
            ),
            Data([
                0, 32, 0, 1, 0, 1, 27, 0, 16, 184, 61, 214, 244, 164, 41, 65, 179, 148, 90, 62, 14, 229, 145, 92, 161, 1, 7, 86, 97, 108, 117, 101, 32, 49,
                1, 32, 0, 1, 0, 1, 27, 0, 16, 184, 61, 214, 244, 164, 41, 65, 179, 148, 90, 62, 14, 229, 145, 92, 162, 1, 7, 86, 97, 108, 117, 101, 32, 50,
                2, 50, 0, 1, 1, 1, 45, 0, 16, 184, 61, 214, 244, 164, 41, 65, 179, 148, 90, 62, 14, 229, 145, 92, 163, 1, 15, 80, 101, 110, 100, 105, 110, 103, 32, 86, 97, 108, 117, 101, 32, 49, 2, 8, 0, 0, 0, 16, 99, 216, 45, 66])
        )
        
    }
    
    func testCodingKeys() {
        
        typealias CodingKeys = ProvisioningState.CodingKeys
        
        for codingKey in ProvisioningState.CodingKeys.allCases {
            
            XCTAssertEqual(CodingKeys(rawValue: codingKey.rawValue), codingKey)
            XCTAssertEqual(CodingKeys(stringValue: codingKey.stringValue), codingKey)
        }
    }
    
    func testUUID() {
        
        let formats: [TLVUUIDFormatting] = [.bytes, .string]
        
        for format in formats {
            
            let value = CustomEncodable(
                data: nil,
                uuid: UUID(),
                number: nil,
                date: nil
            )
            
            var encodedData = Data()
            var encoder = TLVEncoder()
            encoder.uuidFormatting = format
            encoder.log = { print("Encoder:", $0) }
            do {
                encodedData = try encoder.encode(value)
            } catch {
                dump(error)
                XCTFail("Could not encode \(value)")
                return
            }
            
            var decoder = TLVDecoder()
            decoder.uuidFormatting = format
            decoder.log = { print("Decoder:", $0) }
            do {
                let decodedValue = try decoder.decode(CustomEncodable.self, from: encodedData)
                XCTAssertEqual(decodedValue, value)
            } catch {
                dump(error)
                XCTFail("Could not decode \(value)")
            }
        }
    }
    
    func testDate() {
        
        var formats: [TLVDateFormatting] = [
            .secondsSince1970,
            .millisecondsSince1970
        ]
        
        #if !os(WASI)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        formats.append(.formatted(dateFormatter))
        if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
            formats.append(.iso8601)
        }
        #endif

        let date = Date(timeIntervalSince1970: 60 * 60 * 24 * 365)
        
        for format in formats {
            
            let value = CustomEncodable(
                data: nil,
                uuid: nil,
                number: nil,
                date: date
            )
            
            var encodedData = Data()
            var encoder = TLVEncoder()
            encoder.dateFormatting = format
            encoder.log = { print("Encoder:", $0) }
            do {
                encodedData = try encoder.encode(value)
            } catch {
                dump(error)
                XCTFail("Could not encode \(value)")
                return
            }
            
            var decoder = TLVDecoder()
            decoder.dateFormatting = format
            decoder.log = { print("Decoder:", $0) }
            do {
                let decodedValue = try decoder.decode(CustomEncodable.self, from: encodedData)
                XCTAssertEqual(decodedValue, value)
            } catch {
                dump(error)
                XCTFail("Could not decode \(value)")
            }
        }
    }
    
    func testDateSecondsSince1970() {
        
        let date = Date(timeIntervalSince1970: 60 * 60 * 24 * 365)
        
        let value = Transaction(
            id: UUID(),
            date: date,
            description: "Test"
        )
        
        let rawValue = TransactionRaw(
            id: value.id,
            date: value.date.timeIntervalSince1970,
            description: value.description
        )
        
        var encoder = TLVEncoder()
        encoder.dateFormatting = .secondsSince1970
        encoder.log = { print("Encoder:", $0) }
        XCTAssertEqual(try encoder.encode(value), try encoder.encode(rawValue))
    }
    
    func testOutputFormatting() {
        
        var encoder = TLVEncoder()
        encoder.outputFormatting.sortedKeys = true
        encoder.log = { print("Encoder:", $0) }
        
        let value = ProvisioningState(
            state: .provisioning,
            result: .success
        )
        
        let valueUnordered = ProvisioningStateUnordered(
            result: value.result,
            state: value.state
        )
        
        XCTAssertEqual(try encoder.encode(value), try encoder.encode(valueUnordered))
        encoder.outputFormatting.sortedKeys = false
        XCTAssertNotEqual(try encoder.encode(value), try encoder.encode(valueUnordered))
    }
}

private extension TLVCodingTests {
    
    func compare <T: Codable & Equatable> (_ value: T, _ data: Data, shouldFail: Bool = false) {
        
        var didFail = false
        var encoder = TLVEncoder()
        encoder.log = { print("Encoder:", $0) }
        do {
            let encodedData = try encoder.encode(value)
            if shouldFail == false {
                XCTAssertEqual(encodedData, data, "Invalid data \(Array(encodedData))")
            }
        } catch {
            dump(error)
            if shouldFail == false {
                XCTFail("Could not encode \(value)")
            }
            didFail = true
        }
        
        var decoder = TLVDecoder()
        decoder.log = { print("Decoder:", $0) }
        do {
            let decodedValue = try decoder.decode(T.self, from: data)
            XCTAssertEqual(decodedValue, value)
        } catch {
            dump(error)
            if shouldFail == false {
                XCTFail("Could not decode \(value)")
            }
            didFail = true
        }
        
        if shouldFail {
            XCTAssert(didFail, "No error thrown")
        }
    }
}

// MARK: - Supporting Types

public struct Person: Codable, Equatable, Hashable {
    
    public var gender: Gender
    public var name: String
}

public enum Gender: UInt8, Codable {
    
    case male
    case female
}

public struct Transaction: Equatable, Codable {
    
    public let id: UUID
    public let date: Date
    public let description: String
}

public struct TransactionRaw: Equatable, Codable {
    
    public let id: UUID
    public let date: Double
    public let description: String
}

public struct ProvisioningState: Codable, Equatable {
    
    public var state: State
    public var result: Result
    
    public enum State: UInt8, Codable {
        
        case idle = 0x00
        case provisioning = 0x01
    }
    
    public enum Result: UInt8, Codable {
        
        case notAvailible = 0x00
        case success = 0x01
    }
}

internal extension ProvisioningState {
    
    enum CodingKeys: UInt8, TLVCodingKey, CaseIterable {
        
        case state = 0x01
        case result = 0x02
    }
}

extension ProvisioningState.CodingKeys {
    
    var stringValue: String {
        switch self {
        case .state: return "state"
        case .result: return "result"
        }
    }
}

public struct ProvisioningStateUnordered: Codable, Equatable {
    
    typealias CodingKeys = ProvisioningState.CodingKeys

    public var result: ProvisioningState.Result
    public var state: ProvisioningState.State
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(result, forKey: .result)
        try container.encode(state, forKey: .state)
    }
}

public struct Profile: Codable, Equatable {
    
    public var person: Person
    public var friends: [Person]
    public var userInfo: [UInt: String]?
}

public struct Numeric: Codable, Equatable, Hashable {
    
    public var boolean: Bool
    public var int: Int
    public var uint: UInt
    public var float: Float
    public var double: Double
    public var int8: Int8
    public var int16: Int16
    public var int32: Int32
    public var int64: Int64
    public var uint8: UInt8
    public var uint16: UInt16
    public var uint32: UInt32
    public var uint64: UInt64
}

public struct Binary: Codable, Equatable, Hashable {
    
    public var data: Data
    public var value: TLVCodableNumber
}

public enum TLVCodableNumber: UInt16, Equatable, Hashable, Swift.Codable, TLVCodable {
    
    case zero
    case one
    case two
    case three
    
    public init?(tlvData: Data) {
        
        guard let rawValue = UInt16(tlvData: tlvData)?.littleEndian
            else { return nil }
        
        self.init(rawValue: rawValue)
    }
    
    public var tlvData: Data {
        
        return rawValue.littleEndian.tlvData
    }
}

public struct PrimitiveArray: Codable, Equatable {
    
    var strings: [String]
    var integers: [Int]
}

public struct CustomEncodable: Codable, Equatable {
    
    public var data: Data?
    public var uuid: UUID?
    public var number: TLVCodableNumber?
    public var date: Date?
}

public struct DeviceInformation: Equatable, Codable {
    
    public let identifier: UUID
    public let buildVersion: BuildVersion
    public let version: Version
    public var status: Status
    public let features: BitMaskOptionSet<Feature>
}

public extension DeviceInformation {
    
    enum Status: UInt8, Codable {
        case idle = 0x00
        case provisioning = 0x01
        case provisioned = 0x02
    }
    
    struct BuildVersion: RawRepresentable, Equatable, Hashable, Codable {
        
        public let rawValue: UInt64
        
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
        
        public init(from decoder: Decoder) throws {
            
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(RawValue.self)
            self.init(rawValue: rawValue)
        }
        
        public func encode(to encoder: Encoder) throws {
            
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
    
    enum Feature: UInt8, BitMaskOption, Codable {
        
        case bluetooth  = 0b001
        case camera     = 0b010
        case gps        = 0b100
    }
}

public struct Version: Equatable, Hashable, Codable {
    
    public var major: UInt8
    
    public var minor: UInt8
    
    public var patch: UInt8
}

extension Version: TLVCodable {
    
    internal static var length: Int { return 3 }
    
    public init?(tlvData: Data) {
        guard tlvData.count == Version.length
            else { return nil }
        
        self.major = tlvData[0]
        self.minor = tlvData[1]
        self.patch = tlvData[2]
    }
    
    public var tlvData: Data {
        return Data([major, minor, patch])
    }
}

public struct CryptoRequest: Equatable, Codable {
    
    ///  Private key data.
    public let secret: CryptoData
    
    public init(secret: CryptoData) {
        self.secret = secret
    }
}

public protocol SecureData: Hashable {
    
    /// The data length.
    static var length: Int { get }
    
    /// The data.
    var data: Data { get }
    
    /// Initialize with data.
    init?(data: Data)
    
    /// Initialize with random value.
    init()
}

public extension SecureData where Self: Decodable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard let value = Self(data: data) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid number of bytes \(data.count) for \(String(reflecting: Self.self))"))
        }
        self = value
    }
}

public extension SecureData where Self: Encodable {
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

/// Crypto Data
public struct CryptoData: SecureData, Codable {
    
    public static let length = 256 / 8 // 32
    
    public let data: Data
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        self.data = data
    }
    
    /// Initializes with a random value.
    public init() {
        
        self.data = Data(repeating: 0xFF, count: type(of: self).length) // not really random
    }
}

struct CustomEncodableArray: Equatable {
    
    var elements: [Element]
}

extension CustomEncodableArray {
    
    enum Element: Equatable {
        case value(Value)
        case pendingValue(PendingValue)
    }
    
    struct Value: Codable, Equatable {
        let identifier: UUID
        let name: String
    }
    
    struct PendingValue: Codable, Equatable {
        let identifier: UUID
        let name: String
        let expiration: Date
    }
    
    enum ValueType: UInt8, Codable {
        case value
        case pendingValue
    }
}

extension CustomEncodableArray.Element: Codable {
    
    private enum CodingKeys: UInt8, TLVCodingKey, CaseIterable {
        
        case type = 0x00
        case value = 0x01
        
        var stringValue: String {
            switch self {
            case .type: return "type"
            case .value: return "value"
            }
        }
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CustomEncodableArray.ValueType.self, forKey: .type)
        switch type {
        case .value:
            let value = try container.decode(CustomEncodableArray.Value.self, forKey: .value)
            self = .value(value)
        case .pendingValue:
            let pendingValue = try container.decode(CustomEncodableArray.PendingValue.self, forKey: .value)
            self = .pendingValue(pendingValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .value(value):
            try container.encode(CustomEncodableArray.ValueType.value, forKey: .type)
            try container.encode(value, forKey: .value)
        case let .pendingValue(pendingValue):
            try container.encode(CustomEncodableArray.ValueType.pendingValue, forKey: .type)
            try container.encode(pendingValue, forKey: .value)
        }
    }
}

extension CustomEncodableArray: Codable {
    
    public init(from decoder: Decoder) throws {
        self.elements = try .init(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

/// Enum that represents a bit mask flag / option.
///
/// Basically `Swift.OptionSet` for enums.
public protocol BitMaskOption: RawRepresentable, Hashable, CaseIterable where RawValue: FixedWidthInteger { }

public extension Sequence where Element: BitMaskOption {
    
    /// Convert Swift enums for bit mask options into their raw values OR'd.
    var rawValue: Element.RawValue {
        
        @inline(__always)
        get { return reduce(0, { $0 | $1.rawValue }) }
    }
}

public extension BitMaskOption {
    
    /// Whether the enum case is present in the raw value.
    @inline(__always)
    func isContained(in rawValue: RawValue) -> Bool {
        
        return (self.rawValue & rawValue) != 0
    }
    
    @inline(__always)
    static func from(rawValue: RawValue) -> [Self] {
        
        return Self.allCases.filter { $0.isContained(in: rawValue) }
    }
}

// MARK: - BitMaskOptionSet

/// Integer-backed array type for `BitMaskOption`.
///
/// The elements are packed in the integer with bitwise math and stored on the stack.
public struct BitMaskOptionSet <Element: BitMaskOption>: RawRepresentable {
    
    public typealias RawValue = Element.RawValue
    
    public private(set) var rawValue: RawValue
    
    @inline(__always)
    public init(rawValue: RawValue) {
        
        self.rawValue = rawValue
    }
    
    @inline(__always)
    public init() {
        
        self.rawValue = 0
    }
    
    public static var all: BitMaskOptionSet<Element> {
        
        return BitMaskOptionSet<Element>(rawValue: Element.allCases.rawValue)
    }
    
    @inline(__always)
    public mutating func insert(_ element: Element) {
        
        rawValue = rawValue | element.rawValue
    }
    
    @discardableResult
    public mutating func remove(_ element: Element) -> Bool {
        
        guard contains(element) else { return false }
        
        rawValue = rawValue & ~element.rawValue
        
        return true
    }
    
    @inline(__always)
    public mutating func removeAll() {
        
        self.rawValue = 0
    }
    
    @inline(__always)
    public func contains(_ element: Element) -> Bool {
        
        return element.isContained(in: rawValue)
    }
    
    public func contains <S: Sequence> (_ other: S) -> Bool where S.Iterator.Element == Element {
        
        for element in other {
            
            guard element.isContained(in: rawValue)
                else { return false }
        }
        
        return true
    }
    
    public var count: Int {
        
        return Element.allCases.reduce(0, { $0 + ($1.isContained(in: rawValue) ? 1 : 0) })
    }
    
    public var isEmpty: Bool {
        
        return rawValue == 0
    }
}

// MARK: - Sequence Conversion

public extension BitMaskOptionSet {
    
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        self.rawValue = sequence.rawValue
    }
}

extension BitMaskOptionSet: Equatable {
    
    public static func == (lhs: BitMaskOptionSet, rhs: BitMaskOptionSet) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension BitMaskOptionSet: CustomStringConvertible {
    
    public var description: String {
        
        return Element.from(rawValue: rawValue)
            .sorted(by: { $0.rawValue < $1.rawValue })
            .description
    }
}

extension BitMaskOptionSet: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

extension BitMaskOptionSet: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Element...) {
        
        self.init(elements)
    }
}

extension BitMaskOptionSet: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt64) {
        
        self.init(rawValue: numericCast(value))
    }
}

extension BitMaskOptionSet: Sequence {
    
    public func makeIterator() -> IndexingIterator<[Element]> {
        
        return Element.from(rawValue: rawValue).makeIterator()
    }
}

extension BitMaskOptionSet: Codable where BitMaskOptionSet.RawValue: Codable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
