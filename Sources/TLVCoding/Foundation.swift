//
//  Foundation.swift
//  TLVCoding
//
//  Foundation-only conformances, unavailable under Embedded Swift.
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

#if canImport(Foundation) && !hasFeature(Embedded)
import Foundation

// MARK: - UUID

/// `UUID` is encoded as its 16 byte value.
extension UUID: TLVCodable {

    public init?(tlvData: Data) {
        guard tlvData.count == 16 else { return nil }
        let bytes = [UInt8](tlvData)
        self.init(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    public var tlvData: Data {
        withUnsafeBytes(of: uuid) { Data($0) }
    }
}

// MARK: - Date

/// `Date` is encoded as a `Double` of seconds since midnight UTC on January 1, 1970.
extension Date: TLVCodable {

    public init?(tlvData: Data) {
        guard let timeInterval = Double(tlvData: tlvData) else { return nil }
        self.init(timeIntervalSince1970: timeInterval)
    }

    public var tlvData: Data {
        timeIntervalSince1970.tlvData
    }
}

#endif
