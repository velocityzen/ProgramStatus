// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "ProgramStatus",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(name: "ProgramStatus", targets: ["ProgramStatus"])
    ],
    targets: [
        // The reusable library — no @main, pure encoding plus a thin output seam.
        .target(name: "ProgramStatus"),
        .testTarget(
            name: "ProgramStatusTests",
            dependencies: ["ProgramStatus"]
        ),
    ]
)
