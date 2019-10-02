// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TLVCoding",
    products: [
        .library(
            name: "TLVCoding",
            type: .dynamic,
            targets: ["TLVCoding"]
        )
    ],
    targets: [
        .target(name: "TLVCoding", path: "./Sources"),
        .testTarget(name: "TLVCodingTests", dependencies: ["TLVCoding"])
    ],
    swiftLanguageVersions: [.v5]
)
