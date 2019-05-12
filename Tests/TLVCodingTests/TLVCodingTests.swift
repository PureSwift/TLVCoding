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
        ]
    
    func testCodable() {
        
        let data = Data([1, 1, 0, 0, 7, 67, 111, 108, 101, 109, 97, 110])
        
        guard let value = Person(data: data)
            else { XCTFail("Could decode"); return }
        
        XCTAssert(value.data == data, "Could not encode")
        XCTAssert(value == Person(gender: .male, name: "Coleman"))
    }
}

// MARK: - Supporting Types

public struct Person: Codable, Equatable, Hashable {
    
    public enum Gender: UInt8 {
        
        case male
        case female
    }
    
    public var gender: Gender
    
    public var name: String
    
    public init(gender: Gender, name: String) {
        
        self.gender = gender
        self.name = name
    }
    
    public init?(data: Data) {
        
        guard let fields = try? TLVDecoder.decode(data: data, from: (TLVField.Gender.self, TLVField.Name.self))
            else { return nil }
        
        self.gender = fields.0.rawValue
        self.name = fields.1.rawValue
    }
    
    public var data: Data {
        
        let fields: [TLVEncodable] = [
            TLVField.Gender(rawValue: gender),
            TLVField.Name(rawValue: name)
        ]
        
        return TLVEncoder.encode(fields)
    }
    
    private enum TLVField {
        
        enum TypeCode: UInt8, TLVTypeCode {
            
            case name
            case gender
        }
        
        struct Name: TLVCodable, RawRepresentable {
            
            static let typeCode: TLVTypeCode = TypeCode.name
            
            var rawValue: String
            
            init(rawValue: String) {
                
                self.rawValue = rawValue
            }
        }
        
        struct Gender: TLVCodable, RawRepresentable {
            
            static let typeCode: TLVTypeCode = TypeCode.gender
            
            var rawValue: Person.Gender
            
            init(rawValue: Person.Gender) {
                
                self.rawValue = rawValue
            }
        }
    }
}
