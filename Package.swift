// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Symbolicator",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "Symbolicator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing"),
            ]),
        .testTarget(
            name: "SymbolicatorTests",
            dependencies: ["Symbolicator"],
            resources: [
                .copy("Resources/memory_leak.txt"),
                .copy("Resources/MemoryLeakingApp.app.dSYM"),
            ]),
    ]
)
