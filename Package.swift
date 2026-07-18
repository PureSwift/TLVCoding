// swift-tools-version:6.0
import PackageDescription
import CompilerPluginSupport
import class Foundation.ProcessInfo

// get environment variables
let environment = ProcessInfo.processInfo.environment
let dynamicLibrary = environment["SWIFT_BUILD_DYNAMIC_LIBRARY"] != nil
let enableMacros = environment["SWIFTPM_ENABLE_MACROS"] != "0"
let buildDocs = environment["BUILDING_FOR_DOCUMENTATION_GENERATION"] != nil

// force building as dynamic library
let libraryType: PackageDescription.Product.Library.LibraryType? = dynamicLibrary ? .dynamic : nil

var package = Package(
    name: "TLVCoding",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "TLVCoding",
            type: libraryType,
            targets: ["TLVCoding"]
        )
    ],
    targets: [
        .target(
            name: "TLVCoding"
        ),
        .testTarget(
            name: "TLVCodingTests",
            dependencies: ["TLVCoding"]
        )
    ]
)

// SwiftPM plugins
if buildDocs {
    package.dependencies += [
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin.git",
            from: "1.4.5"
        )
    ]
}

if enableMacros {
    let version: Version
    #if swift(>=6.3)
    version = "603.0.1"
    #elseif swift(>=6.2)
    version = "602.0.0"
    #elseif swift(>=6.1)
    version = "601.0.1"
    #else
    version = "600.0.1"
    #endif
    package.targets[0].swiftSettings = [
        .define("SWIFTPM_ENABLE_MACROS")
    ]
    package.dependencies += [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: version
        )
    ]
    package.targets += [
        .macro(
            name: "TLVCodingMacros",
            dependencies: [
                .product(
                    name: "SwiftSyntaxMacros",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                )
            ]
        )
    ]
    package.targets[0].dependencies += [
        "TLVCodingMacros"
    ]
    package.targets += [
        .testTarget(
            name: "TLVCodingMacrosTests",
            dependencies: [
                "TLVCodingMacros",
                .product(
                    name: "SwiftSyntaxMacros",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntaxMacroExpansion",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftParser",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ]
        )
    ]
}
