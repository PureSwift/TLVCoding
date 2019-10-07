// swift-tools-version:5.0
import PackageDescription

#if os(Linux)
let libraryType: PackageDescription.Product.Library.LibraryType = .dynamic
#else
let libraryType: PackageDescription.Product.Library.LibraryType = .static
#endif

let package = Package(
    name: "TLVCoding",
    products: [
        .library(
            name: "TLVCoding",
            type: libraryType,
            targets: ["TLVCoding"]
        )
    ],
    targets: [
        .target(name: "TLVCoding", path: "./Sources"),
        .testTarget(name: "TLVCodingTests", dependencies: ["TLVCoding"])
    ],
    swiftLanguageVersions: [.v5]
)
