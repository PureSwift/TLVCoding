//
//  Data.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 5/12/19.
//  Copyright © 2019 PureSwift. All rights reserved.
//

import Foundation

internal extension Data {
    
    func subdataNoCopy(in range: Range<Int>) -> Data {
        
        // stored in heap, can reuse buffer
        if count > Data.inlineBufferSize {
            return withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
                Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: buffer.baseAddress!.advanced(by: range.lowerBound)),
                     count: range.count,
                     deallocator: .none)
            }
        } else {
            // stored in stack, must copy
            return subdata(in: range)
        }
    }
    
    func suffixNoCopy(from index: Int) -> Data {
        return subdataNoCopy(in: index ..< count)
    }
    
    func suffixCheckingBounds(from start: Int) -> Data {
        if count > start {
            return Data(suffix(from: start))
        } else {
            return Data()
        }
    }
}

private extension Data {
    
    /// Size of the inline buffer for `Foundation.Data` used in Swift 5.
    ///
    /// Used to determine wheather data is stored on stack or in heap.
    static var inlineBufferSize: Int {
        
        // Keep up to date
        // https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/Data.swift#L621
        #if arch(x86_64) || arch(arm64) || arch(arm64_32) || arch(s390x) || arch(powerpc64) || arch(powerpc64le)
        typealias Buffer = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) //len  //enum
        #elseif arch(i386) || arch(arm) || arch(wasm32)
        typealias Buffer = (UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8)
        #else
        #error("Platform not supported")
        #endif
        
        return MemoryLayout<Buffer>.size
    }
}
