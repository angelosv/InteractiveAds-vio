// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VioTVSDK",
    platforms: [
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "VioTV",
            targets: ["VioTV"]
        )
    ],
    targets: [
        .target(
            name: "VioTV",
            path: "Sources/VioTV"
        )
    ]
)
