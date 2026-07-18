//
//  TLVCodingMacrosTests.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import TLVCodingMacros

final class TLVCodingMacrosTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "TLVCodable": TLVCodableMacro.self
    ]

    func testGeneratedCodingKeys() {
        assertMacroExpansion(
            """
            @TLVCodable
            public struct Person: Equatable {

                public var gender: Gender

                public var name: String
            }
            """,
            expandedSource: """
            public struct Person: Equatable {

                public var gender: Gender

                public var name: String

                public enum CodingKeys: UInt8, TLVCoding.TLVCodingKey {
                    case gender = 0
                    case name = 1
                }

                public init?(tlvData: Data) {
                    guard let container = TLVContainer(data: tlvData) else {
                        return nil
                    }
                    guard let gender = container.decode(Gender.self, forKey: CodingKeys.gender) else {
                        return nil
                    }
                    self.gender = gender
                    guard let name = container.decode(String.self, forKey: CodingKeys.name) else {
                        return nil
                    }
                    self.name = name
                }

                public var tlvData: Data {
                    var container = TLVContainer()
                    container.encode(self.gender, forKey: CodingKeys.gender)
                    container.encode(self.name, forKey: CodingKeys.name)
                    return container.data
                }
            }

            extension Person: TLVCoding.TLVCodable {
            }
            """,
            macros: testMacros
        )
    }

    func testExplicitCodingKeys() {
        assertMacroExpansion(
            """
            @TLVCodable
            struct ProvisioningState {

                var state: State

                enum CodingKeys: UInt8, TLVCodingKey {
                    case state = 0x01
                }
            }
            """,
            expandedSource: """
            struct ProvisioningState {

                var state: State

                enum CodingKeys: UInt8, TLVCodingKey {
                    case state = 0x01
                }

                init?(tlvData: Data) {
                    guard let container = TLVContainer(data: tlvData) else {
                        return nil
                    }
                    guard let state = container.decode(State.self, forKey: CodingKeys.state) else {
                        return nil
                    }
                    self.state = state
                }

                var tlvData: Data {
                    var container = TLVContainer()
                    container.encode(self.state, forKey: CodingKeys.state)
                    return container.data
                }
            }

            extension ProvisioningState: TLVCoding.TLVCodable {
            }
            """,
            macros: testMacros
        )
    }

    func testOptionalProperty() {
        assertMacroExpansion(
            """
            @TLVCodable
            struct CustomEncodable {

                var data: Data?
            }
            """,
            expandedSource: """
            struct CustomEncodable {

                var data: Data?

                enum CodingKeys: UInt8, TLVCoding.TLVCodingKey {
                    case data = 0
                }

                init?(tlvData: Data) {
                    guard let container = TLVContainer(data: tlvData) else {
                        return nil
                    }
                    if container.contains(CodingKeys.data) {
                        guard let data = container.decode(Data.self, forKey: CodingKeys.data) else {
                            return nil
                        }
                        self.data = data
                    } else {
                        self.data = nil
                    }
                }

                var tlvData: Data {
                    var container = TLVContainer()
                    container.encode(self.data, forKey: CodingKeys.data)
                    return container.data
                }
            }

            extension CustomEncodable: TLVCoding.TLVCodable {
            }
            """,
            macros: testMacros
        )
    }
}
