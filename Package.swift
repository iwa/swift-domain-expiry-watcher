// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "domain-expiry-watcher",
    platforms: [
        // Specify the platforms supported by this package.
        .macOS(.v13), // Minimum macOS version
    ],
    dependencies: [
        .package(url: "https://github.com/mihaelisaev/VaporCron.git", from: "2.6.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.26.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "domain-expiry-watcher",
            dependencies: [
                .product(name: "VaporCron", package: "VaporCron"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ])
    ]
)
