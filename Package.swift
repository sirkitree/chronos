// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChronoGuard",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
    ],
    targets: [
        .executableTarget(
            name: "ChronoGuard",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),
        .testTarget(
            name: "ChronoGuardTests",
            dependencies: ["ChronoGuard"]
        )
    ]
)
