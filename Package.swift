// swift-tools-version:5.1
import PackageDescription

let libraryType: PackageDescription.Product.Library.LibraryType = .static

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
    ]
)
