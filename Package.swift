// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnsplashAPIWrapper",
    platforms: [
        .macOS(.v15),
        .macCatalyst(.v18),
        .iOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "Splashy",
            targets: ["Splashy"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Splashy"
        ),
        .testTarget(
            name: "UnsplashAPIWrapperTests",
            dependencies: ["Splashy"]
        ),
    ]
)
