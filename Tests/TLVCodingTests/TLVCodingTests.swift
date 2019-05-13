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
        ("testEncode", testEncode),
        ("testCodingKeys", testCodingKeys)
    ]
    
    func testEncode() {
        
        func encode <T: Encodable> (_ value: T, _ data: Data) {
            
            let encoder = TLVEncoder()
            do {
                let encodedData = try encoder.encode(value)
                XCTAssertEqual(encodedData, data)
            } catch {
                dump(error)
                XCTFail("Could not encode \(value)")
            }
        }
        
        encode(Person(gender: .male, name: "Coleman"),
               Data([0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110]))
        
        encode(ProvisioningState(state: .idle, result: .notAvailible),
               Data([0x01, 0x01, 0x00, 0x02, 0x01, 0x00]))
        
        encode(ProvisioningState(state: .provisioning, result: .notAvailible),
               Data([0x01, 0x01, 0x01, 0x02, 0x01, 0x00]))
    }
    
    func testDecode() {
        
        func decode <T: Codable & Equatable> (_ value: T, _ data: Data) {
            
            let decoder = TLVDecoder()
            do {
                let decodedValue = try decoder.decode(T.self, from: data)
                XCTAssertEqual(decodedValue, value)
            } catch {
                dump(error)
                XCTFail("Could not decode \(value)")
            }
        }
        
        decode(Person(gender: .male, name: "Coleman"),
               Data([0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110]))
        
        decode(ProvisioningState(state: .idle, result: .notAvailible),
               Data([0x01, 0x01, 0x00, 0x02, 0x01, 0x00]))
        
        decode(ProvisioningState(state: .provisioning, result: .notAvailible),
               Data([0x01, 0x01, 0x01, 0x02, 0x01, 0x00]))
    }
    
    func testCodingKeys() {
        
        typealias CodingKeys = ProvisioningState.CodingKeys
        
        for codingKey in ProvisioningState.CodingKeys.allCases {
            
            XCTAssertEqual(CodingKeys(rawValue: codingKey.rawValue), codingKey)
            XCTAssertEqual(CodingKeys(stringValue: codingKey.stringValue), codingKey)
        }
    }
}

// MARK: - Supporting Types

public enum Gender: UInt8, Codable {
    
    case male
    case female
}

public struct Person: Codable, Equatable, Hashable {
    
    public var gender: Gender
    
    public var name: String
    
    public init(gender: Gender, name: String) {
        
        self.gender = gender
        self.name = name
    }
}

public struct ProvisioningState: Codable, Equatable, Hashable {
    
    public var state: State
    
    public var result: Result
}

internal extension ProvisioningState {
    
    enum CodingKeys: UInt8, TLVCodingKey, CaseIterable {
        
        case state = 0x01
        case result = 0x02
        
        var stringValue: String {
            switch self {
            case .state: return "state"
            case .result: return "result"
            }
        }
    }
    
}

public extension ProvisioningState {
    
    enum State: UInt8, Codable {
        
        case idle = 0x00
        case provisioning = 0x01
        case provisioned = 0x02
        case declined = 0x03
    }
    
    enum Result: UInt8, Codable {
        
        case notAvailible = 0x00
        case success = 0x01
        case invalidConfiguration = 0x02
        case networkOutOfRange = 0x03
        case invalidKey = 0x04
        case otherError = 0x05
        case connectFailed = 0x06
        case connectTimeout = 0x07
        case insufficientNetwork = 0x08
    }
}
