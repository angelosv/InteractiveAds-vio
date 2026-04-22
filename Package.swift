// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VioTVSDK",
    platforms: [
        .tvOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "VioTVCore",
            targets: ["VioTVCore"]
        ),
        .library(
            name: "VioTVCommerce",
            targets: ["VioTVCommerce"]
        ),
        .library(
            name: "VioTVUI",
            targets: ["VioTVUI"]
        ),
        .library(
            name: "VioTV",
            targets: ["VioTV"]
        )
    ],
    targets: [
        .target(
            name: "VioTVCore",
            path: "Sources/VioTVCore"
        ),
        .target(
            name: "VioTVCommerce",
            dependencies: ["VioTVCore"],
            path: "Sources/VioTVCommerce"
        ),
        .target(
            name: "VioTVUI",
            dependencies: ["VioTVCore"],
            path: "Sources/VioTVUI"
        ),
        .target(
            name: "VioTV",
            dependencies: ["VioTVCore", "VioTVCommerce", "VioTVUI"],
            path: "Sources/VioTV",
            sources: ["VioTV.swift"]
        ),
        .testTarget(
            name: "VioTVCoreTests",
            dependencies: ["VioTVCore"],
            path: "Tests/VioTVCoreTests"
        ),
        .testTarget(
            name: "VioTVCommerceTests",
            dependencies: ["VioTVCommerce", "VioTVCore"],
            path: "Tests/VioTVCommerceTests"
        )
    ]
)
