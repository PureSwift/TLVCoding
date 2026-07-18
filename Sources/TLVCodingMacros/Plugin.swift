//
//  Plugin.swift
//  TLVCoding
//
//  Created by Alsey Coleman Miller on 7/17/26.
//  Copyright © 2026 PureSwift. All rights reserved.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TLVCodingMacrosPlugin: CompilerPlugin {

    let providingMacros: [Macro.Type] = [
        TLVCodableMacro.self
    ]
}
