// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Commstime",
    products: [
        .executable(
            name: "Commstime",
            targets: ["Commstime"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        //.package(url: "https://github.com/typelift/Concurrent.git", .branch("master"))
        .package(url: "https://github.com/typelift/Concurrent.git", .revision("6095c2ce07b8f065abc10710b214808fec0db2b2"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Commstime",
            dependencies: ["Concurrent"]),
        .testTarget(
            name: "CommstimeTests",
            dependencies: ["Commstime"]),
    ]
)
