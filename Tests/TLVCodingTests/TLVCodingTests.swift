//
//  TLVCodingTests.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation
import XCTest
#if canImport(BinaryParsing)
import BinaryParsing
#endif
@testable import TLVCoding

final class TLVCodingTests: XCTestCase {

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
                ]
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
                ]
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
    }

    func testCodingKeys() {

        typealias CodingKeys = ProvisioningState.CodingKeys

        XCTAssertEqual(CodingKeys.state.rawValue, 0x01)
        XCTAssertEqual(CodingKeys.result.rawValue, 0x02)

        for codingKey in [CodingKeys.state, .result] {
            XCTAssertEqual(CodingKeys(rawValue: codingKey.rawValue), codingKey)
            XCTAssertEqual(CodingKeys(code: codingKey.code), codingKey)
            XCTAssertEqual(codingKey.code.rawValue, codingKey.rawValue)
        }

        // generated coding keys are sequential, in declaration order
        XCTAssertEqual(Person.CodingKeys.gender.rawValue, 0)
        XCTAssertEqual(Person.CodingKeys.name.rawValue, 1)
    }

    func testContainer() {

        let value = Person(gender: .male, name: "Coleman")

        // explicit encoding matches the macro-generated implementation
        var container = TLVContainer()
        container.encode(value.gender, forKey: Person.CodingKeys.gender)
        container.encode(value.name, forKey: Person.CodingKeys.name)
        XCTAssertEqual(container.data, value.tlvData)

        // keyed access
        guard let decoded = TLVContainer(data: container.data) else {
            XCTFail("Could not parse container")
            return
        }
        XCTAssertEqual(decoded, container)
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssert(decoded.contains(Person.CodingKeys.gender))
        XCTAssertEqual(decoded.decode(Gender.self, forKey: Person.CodingKeys.gender), .male)
        XCTAssertEqual(decoded.decode(String.self, forKey: Person.CodingKeys.name), "Coleman")
        XCTAssertEqual(decoded[TLVTypeCode(rawValue: 1)], Data([67, 111, 108, 101, 109, 97, 110]))

        // invalid data
        XCTAssertNil(TLVContainer(data: Data([0])), "Missing length byte")
        XCTAssertNil(TLVContainer(data: Data([0, 2, 0])), "Truncated value")
    }

    func testUUID() {

        let value = CustomEncodable(
            data: nil,
            uuid: UUID(),
            number: nil,
            date: nil
        )

        let encodedData = value.tlvData
        guard let decodedValue = CustomEncodable(tlvData: encodedData) else {
            XCTFail("Could not decode \(value)")
            return
        }
        XCTAssertEqual(decodedValue, value)

        // 16 byte big endian value
        let uuid = UUID(uuidString: "B83DD6F4-A429-41B3-945A-3E0EE5915CA1")!
        XCTAssertEqual(uuid.tlvData, Data([184, 61, 214, 244, 164, 41, 65, 179, 148, 90, 62, 14, 229, 145, 92, 161]))
        XCTAssertEqual(UUID(tlvData: uuid.tlvData), uuid)
    }

    func testDate() {

        let date = Date(timeIntervalSince1970: 60 * 60 * 24 * 365)

        let value = CustomEncodable(
            data: nil,
            uuid: nil,
            number: nil,
            date: date
        )

        let encodedData = value.tlvData
        guard let decodedValue = CustomEncodable(tlvData: encodedData) else {
            XCTFail("Could not decode \(value)")
            return
        }
        XCTAssertEqual(decodedValue, value)

        // encoded as seconds since 1970
        XCTAssertEqual(date.tlvData, date.timeIntervalSince1970.tlvData)
    }

    #if canImport(BinaryParsing)
    func testBinaryParsing() throws {

        let data = Data([0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110])

        // parse a container from raw data
        let container = try TLVContainer(parsing: data)
        XCTAssertEqual(container, TLVContainer(data: data))
        XCTAssertEqual(container.items.count, 2)
        XCTAssertEqual(container.decode(Gender.self, forKey: Person.CodingKeys.gender), .male)
        XCTAssertEqual(container.decode(String.self, forKey: Person.CodingKeys.name), "Coleman")

        // parse items sequentially from a span
        try data.withParserSpan { input in
            let gender = try TLVItem(parsing: &input)
            XCTAssertEqual(gender.type, 0)
            XCTAssertEqual(gender.value, Data([0]))
            let name = try TLVItem(parsing: &input)
            XCTAssertEqual(name.type, 1)
            XCTAssertEqual(name.value, Data([67, 111, 108, 101, 109, 97, 110]))
            XCTAssert(input.isEmpty)
        }

        // parse a type code
        try Data([0xAA]).withParserSpan { input in
            XCTAssertEqual(try TLVTypeCode(parsing: &input), 0xAA)
        }

        // empty data is a valid empty container
        XCTAssertEqual(try TLVContainer(parsing: Data()).items, [])

        // invalid data throws
        XCTAssertThrowsError(try TLVContainer(parsing: Data([0])), "Missing length byte")
        XCTAssertThrowsError(try TLVContainer(parsing: Data([0, 2, 0])), "Truncated value")
    }
    #endif
}

private extension TLVCodingTests {

    func compare <T: TLVCodable & Equatable> (_ value: T, _ data: Data, shouldFail: Bool = false) {

        if shouldFail == false {
            let encodedData = value.tlvData
            XCTAssertEqual(encodedData, data, "Invalid data \(Array(encodedData))")
        }

        if let decodedValue = T(tlvData: data) {
            if shouldFail {
                XCTFail("Decoding should have failed for \(Array(data))")
            } else {
                XCTAssertEqual(decodedValue, value)
            }
        } else if shouldFail == false {
            XCTFail("Could not decode \(value)")
        }
    }
}

// MARK: - Supporting Types

@TLVCodable
public struct Person: Equatable, Hashable {

    public var gender: Gender

    public var name: String

    public init(gender: Gender, name: String) {
        self.gender = gender
        self.name = name
    }
}

public enum Gender: UInt8, TLVCodable {

    case male
    case female
}

@TLVCodable
public struct ProvisioningState: Equatable {

    public var state: State

    public var result: Result

    public init(state: State, result: Result) {
        self.state = state
        self.result = result
    }

    public enum CodingKeys: UInt8, TLVCodingKey {

        case state = 0x01
        case result = 0x02
    }

    public enum State: UInt8, TLVCodable {

        case idle = 0x00
        case provisioning = 0x01
    }

    public enum Result: UInt8, TLVCodable {

        case notAvailible = 0x00
        case success = 0x01
    }
}

@TLVCodable
public struct Profile: Equatable {

    public var person: Person

    public var friends: [Person]

    public init(person: Person, friends: [Person]) {
        self.person = person
        self.friends = friends
    }
}

@TLVCodable
public struct Numeric: Equatable, Hashable {

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

    public init(
        boolean: Bool,
        int: Int,
        uint: UInt,
        float: Float,
        double: Double,
        int8: Int8,
        int16: Int16,
        int32: Int32,
        int64: Int64,
        uint8: UInt8,
        uint16: UInt16,
        uint32: UInt32,
        uint64: UInt64
    ) {
        self.boolean = boolean
        self.int = int
        self.uint = uint
        self.float = float
        self.double = double
        self.int8 = int8
        self.int16 = int16
        self.int32 = int32
        self.int64 = int64
        self.uint8 = uint8
        self.uint16 = uint16
        self.uint32 = uint32
        self.uint64 = uint64
    }
}

@TLVCodable
public struct Binary: Equatable, Hashable {

    public var data: Data

    public var value: TLVCodableNumber

    public init(data: Data, value: TLVCodableNumber) {
        self.data = data
        self.value = value
    }
}

public enum TLVCodableNumber: UInt16, TLVCodable {

    case zero
    case one
    case two
    case three
}

@TLVCodable
public struct PrimitiveArray: Equatable {

    public var strings: [String]

    public var integers: [Int]

    public init(strings: [String], integers: [Int]) {
        self.strings = strings
        self.integers = integers
    }
}

@TLVCodable
public struct CustomEncodable: Equatable {

    public var data: Data?

    public var uuid: UUID?

    public var number: TLVCodableNumber?

    public var date: Date?

    public init(
        data: Data?,
        uuid: UUID?,
        number: TLVCodableNumber?,
        date: Date?
    ) {
        self.data = data
        self.uuid = uuid
        self.number = number
        self.date = date
    }
}

/// Hand-written `TLVCodable` conformance with a custom binary layout.
public struct Version: Equatable, Hashable {

    public var major: UInt8

    public var minor: UInt8

    public var patch: UInt8

    public init(major: UInt8, minor: UInt8, patch: UInt8) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

extension Version: TLVCodable {

    internal static var length: Int { 3 }

    public init?(tlvData: Data) {
        guard tlvData.count == Version.length
            else { return nil }

        self.major = tlvData[0]
        self.minor = tlvData[1]
        self.patch = tlvData[2]
    }

    public var tlvData: Data {
        Data([major, minor, patch])
    }
}
