// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "ProgramStatus",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "ProgramStatus", targets: ["ProgramStatus"]),
        .executable(name: "program-status", targets: ["program-status"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
        .package(url: "https://github.com/velocityzen/fp-swift", from: "4.2.1"),
        .package(url: "https://github.com/velocityzen/fp-swift-bracket", from: "2.1.0"),
    ],
    targets: [
        // The reusable library — no @main, pure encoding plus a thin output seam.
        .target(
            name: "ProgramStatus",
            dependencies: [
                .product(name: "FP", package: "fp-swift"),
                .product(name: "FPBracket", package: "fp-swift-bracket"),
            ]
        ),
        // The CLI front-end — parses args, builds a report, sends it.
        .executableTarget(
            name: "program-status",
            dependencies: [
                "ProgramStatus",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FP", package: "fp-swift"),
            ]
        ),
        .testTarget(
            name: "ProgramStatusTests",
            dependencies: [
                "ProgramStatus",
                .product(name: "FP", package: "fp-swift"),
            ]
        ),
    ]
)
