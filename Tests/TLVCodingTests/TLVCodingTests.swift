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
    
    static var allTests = [
        ("testCodable", testCodable),
        ("testCodingKeys", testCodingKeys)
    ]
    
    func testCodable() {
        
        func test <T: Codable & Equatable> (_ value: T, _ data: Data) {
            
            var encoder = TLVEncoder()
            encoder.log = { print("Encoder:", $0) }
            do {
                let encodedData = try encoder.encode(value)
                XCTAssertEqual(encodedData, data, "Invalid data \(Array(encodedData))")
            } catch {
                dump(error)
                XCTFail("Could not encode \(value)")
            }
            
            var decoder = TLVDecoder()
            decoder.log = { print("Decoder:", $0) }
            do {
                let decodedValue = try decoder.decode(T.self, from: data)
                XCTAssertEqual(decodedValue, value)
            } catch {
                dump(error)
                XCTFail("Could not decode \(value)")
            }
        }
        
        test(Person(gender: .male, name: "Coleman"),
            Data([0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110]))
        
        test(ProvisioningState(state: .idle, result: .notAvailible),
            Data([0x01, 0x01, 0x00, 0x02, 0x01, 0x00]))
        
        test(ProvisioningState(state: .provisioning, result: .notAvailible),
            Data([0x01, 0x01, 0x01, 0x02, 0x01, 0x00]))
        
        test(Numeric(
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
        
        test(
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
        
        test(
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
        
        test(
            Binary(
                data: Data([0x01, 0x02, 0x03, 0x04]),
                value: .one
            ),
            Data([0, 4, 1, 2, 3, 4, 1, 2, 1, 0])
        )
        
        test(
            PrimitiveArray(
                strings: ["1", "two", "three", ""],
                integers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            ),
            Data([0, 17, 0, 1, 49, 1, 3, 116, 119, 111, 2, 5, 116, 104, 114, 101, 101, 3, 0, 1, 60, 0, 4, 1, 0, 0, 0, 1, 4, 2, 0, 0, 0, 2, 4, 3, 0, 0, 0, 3, 4, 4, 0, 0, 0, 4, 4, 5, 0, 0, 0, 5, 4, 6, 0, 0, 0, 6, 4, 7, 0, 0, 0, 7, 4, 8, 0, 0, 0, 8, 4, 9, 0, 0, 0, 9, 4, 10, 0, 0, 0])
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
        
        let formats: [TLVUUIDFormat] = [.bytes, .string]
        
        for format in formats {
            
            let value = CustomEncodable(
                data: nil,
                uuid: UUID(),
                number: nil
            )
            
            var encodedData = Data()
            var encoder = TLVEncoder()
            encoder.uuidFormat = format
            encoder.log = { print("Encoder:", $0) }
            do {
                encodedData = try encoder.encode(value)
            } catch {
                dump(error)
                XCTFail("Could not encode \(value)")
                return
            }
            
            var decoder = TLVDecoder()
            decoder.uuidFormat = format
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

#if swift(>=4.2)
#else
protocol CaseIterable: Hashable {
    
    static var allCases: Set<Self> { get }
}

extension ProvisioningState.CodingKeys {
    
    static let allCases: Set<ProvisioningState.CodingKeys> = [.state, .result]
    
    init?(stringValue: String) {
        
        guard let value = type(of: self).allCases.first(where: { $0.stringValue == stringValue })
            else { return nil }
        
        self = value
    }
}
#endif

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
}
