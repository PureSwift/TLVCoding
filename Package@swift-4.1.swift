// swift-tools-version:4.1
import PackageDescription

let package = Package(name: "TLVCoding",
                      products: [
                        .library(
                            name: "TLVCoding",
                            targets: ["TLVCoding"]
                        )
                        ],
                      targets: [
                        .target(name: "TLVCoding", path: "./Sources"),
                        .testTarget(name: "TLVCodingTests", dependencies: ["TLVCoding"])
                        ],
                      swiftLanguageVersions: [4])