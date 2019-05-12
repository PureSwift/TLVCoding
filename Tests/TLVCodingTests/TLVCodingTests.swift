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
        ]
    
    func testEncode() {
        
        let data = Data([0, 1, 0, 1, 7, 67, 111, 108, 101, 109, 97, 110])
        let value = Person(gender: .male, name: "Coleman")
        
        let encoder = TLVEncoder()
        var encodedData = Data()
        XCTAssertNoThrow(encodedData = try encoder.encode(value))
        XCTAssertEqual(encodedData, data)
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
