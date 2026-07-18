//
//  Macros.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if !hasFeature(Embedded) && SWIFTPM_ENABLE_MACROS
/// Generates `TLVCodable` conformance for a struct.
///
/// Adds a `CodingKeys` enum (unless one is declared), an `init?(tlvData:)` initializer,
/// and a `tlvData` computed property that encode the stored properties in declaration order.
///
/// ```swift
/// @TLVCodable
/// struct ProvisioningState: Equatable {
///
///     var state: State
///
///     var result: Result
///
///     enum CodingKeys: UInt8, TLVCodingKey {
///         case state  = 0x01
///         case result = 0x02
///     }
/// }
/// ```
///
/// Under Embedded Swift, write the equivalent conformance by hand.
@attached(member, names: named(CodingKeys), named(init(tlvData:)), named(tlvData))
@attached(extension, conformances: TLVEncodable, TLVDecodable)
public macro TLVCodable() = #externalMacro(
    module: "TLVCodingMacros",
    type: "TLVCodableMacro"
)
#endif
