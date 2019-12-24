//
//  TLVCoding.swift
//  PureSwift
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

/// Type-Length-Value Codable
public typealias TLVCodable = TLVEncodable & TLVDecodable

/// TLV Decodable type
public protocol TLVDecodable: Decodable {
    
    init?(tlvData: Data)
}

/// TLV Encodable type
public protocol TLVEncodable: Encodable {
    
    var tlvData: Data { get }
}
