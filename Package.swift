// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swon",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "swon",
            targets: ["SWON"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest"),
    ],
    targets: [
        .target(
            name: "SWON",
            dependencies: [
                "SWON_C",
                "SWONMacros"
            ]
        ),
        .target(name: "SWON_C"),
        .macro(
            name: "SWONMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "SWON_C"
            ]
        ),
        .testTarget(
            name: "SWONTests",
            dependencies: ["SWON"],
            resources: [.process("Resources")]
        )
    ]
)
