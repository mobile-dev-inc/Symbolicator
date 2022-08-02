// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Symbolicator",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(name: "symbolicator", targets: ["Symbolicator"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/mobile-dev-inc/swift-parsing", from: "0.10.1"),
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
                .copy("Resources/memory_leak_with_stacktrace.txt"),
                .copy("Resources/memory_leak_with_symbolicated_stacktrace.txt"),
                .copy("Resources/MemoryLeakingApp.app.dSYM"),
                .copy("Resources/non_symbolicated_crash.crash"),
                .copy("Resources/crash.app.dSYM"),
                .copy("Resources/memory_leak_unsymbolicated.txt")
            ]),
    ]
)
