// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-game-zero",
    products: [ 
        .library(name: "sgz", targets: ["sgz"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "sgz",
            dependencies: ["clibs"]),
        .target(
            name: "hello",
            dependencies: ["sgz"]),
        .testTarget(
            name: "hello_sdlTests",
            dependencies: ["hello"]),
    ]
)

#if os(Linux)
        package.targets.append(.systemLibrary(name: "clibs"))
#else
        package.targets.append(.systemLibrary(name: "clibs", path: "Sources/clibs_mac"))
#endif

