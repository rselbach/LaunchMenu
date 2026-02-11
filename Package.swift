// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LauncherMenu",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "LauncherMenu",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ]
        ),
        .testTarget(
            name: "LauncherMenuTests",
            dependencies: ["LauncherMenu"]
        ),
    ]
)
