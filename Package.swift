// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Symbolicator",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/mobile-dev-inc/swift-parsing", from: "0.10.1"),
        .package(url: "https://github.com/berikv/generic-json-swift", from: "2.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "Symbolicator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "GenericJSON", package: "generic-json-swift")
            ]),
        .testTarget(
            name: "SymbolicatorTests",
            dependencies: ["Symbolicator"],
            resources: [
                .copy("Resources/memory_leak_no_stack.txt"),
                .copy("Resources/memory_leak_with_stacktrace.txt"),
                .copy("Resources/memory_leak_with_symbolicated_stacktrace.txt"),
                .copy("Resources/MemoryLeakingApp.app.dSYM"),
                .copy("Resources/non_symbolicated_crash.crash"),
                .copy("Resources/crash.app.dSYM"),
                .copy("Resources/memory_leak_unsymbolicated.txt"),
                .copy("Resources/memory_leak_unicode_unsymbolicated.txt"),
                .copy("Resources/MemoryLeakingApp-2022-08-05-132419.crash"),
                .copy("Resources/MemoryLeakingApp-2022-08-05-132419.ips"),
                .copy("Resources/memory_leak_with_excludes.txt"),
            ]),
    ]
)
