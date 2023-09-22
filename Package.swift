// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftOCA",
    platforms: [
        // specify each minimum deployment requirement,
        // otherwise the platform default minimum is used.
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them
        // visible to other packages.
        .library(
            name: "SwiftOCA",
            targets: ["SwiftOCA"]
        ),
        .library(
            name: "SwiftOCADevice",
            targets: ["SwiftOCADevice"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.1.0"),
        .package(url: "https://github.com/PADL/swift-binary-coder", branch: "inferno"),
        .package(url: "https://github.com/lhoward/AsyncExtensions", branch: "linux"),
        .package(url: "https://github.com/swhitty/FlyingFox", branch: "main"),
        .package(url: "https://github.com/PADL/IORingSwift", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a
        // test suite.
        // Targets can depend on other targets in this package, and on products in packages which
        // this package depends on.
        .systemLibrary(
            name: "dnssd"
        ),
        .target(
            name: "SwiftOCA",
            dependencies: [
                "AsyncExtensions",
                .product(name: "BinaryCoder", package: "swift-binary-coder"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(
                    name: "FlyingSocks",
                    package: "FlyingFox",
                    condition: .when(platforms: [.macOS, .iOS])
                ),
                .product(
                    name: "IORing",
                    package: "IORingSwift",
                    condition: .when(platforms: [.linux])
                ),
                .product(
                    name: "IORingUtils",
                    package: "IORingSwift",
                    condition: .when(platforms: [.linux])
                ),
            ]
        ),
        .target(
            name: "SwiftOCADevice",
            dependencies: [
                "SwiftOCA",
                "dnssd",
                .product(
                    name: "FlyingSocks",
                    package: "FlyingFox",
                    condition: .when(platforms: [.macOS, .iOS])
                ),
                .product(
                    name: "IORing",
                    package: "IORingSwift",
                    condition: .when(platforms: [.linux])
                ),
                .product(
                    name: "IORingUtils",
                    package: "IORingSwift",
                    condition: .when(platforms: [.linux])
                ),
            ]
        ),
        .executableTarget(
            name: "OCADevice",
            dependencies: [
                "SwiftOCADevice",
                .product(name: "FlyingSocks", package: "FlyingFox"),
            ],
            path: "Examples/OCADevice"
        ),
        .testTarget(
            name: "SwiftOCADeviceTests",
            dependencies: [
                .target(name: "SwiftOCADevice"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
