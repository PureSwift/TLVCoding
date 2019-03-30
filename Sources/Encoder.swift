//
//  Encoder.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 3/8/18.
//  Copyright © 2018 PureSwift. All rights reserved.
//

import Foundation

public struct TLVEncoder {
    
    public static func encode(_ encodables: [TLVEncodable]) -> Data {
        
        var data = Data()
        
        for encodable in encodables {
            
            let type = Swift.type(of: encodable).typeCode.rawValue
            
            let valueData = encodable.valueData
            
            assert(valueData.isEmpty == false)
            
            let length = UInt8(valueData.count)
            
            data.append(Data([type, length]))
            data.append(valueData)
        }
        
        return data
    }
}
