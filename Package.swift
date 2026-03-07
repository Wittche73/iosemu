// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocalCompat",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "CompatCore", targets: ["CompatCore"]),
        .library(name: "CompatUIKit", targets: ["CompatUIKit"]),
    ],
    targets: [
        .target(name: "CompatCore", path: "Sources/CompatCore"),
        .target(name: "CompatUIKit", dependencies: ["CompatCore"], path: "Sources/CompatUIKit"),
        .testTarget(name: "CompatCoreTests", dependencies: ["CompatCore"], path: "Tests/CompatCoreTests"),
    ]
)
