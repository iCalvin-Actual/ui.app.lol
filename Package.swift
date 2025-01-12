// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "omgui",
    platforms: [
        .iOS("17.0"),
        .macOS("13.0"),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "omgui",
            targets: ["omgui"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/iCalvin-Actual/swift-markdown-ui", 
            branch: "main"
        ),
        .package(
            url: "https://github.com/iCalvin-Actual/PunycodeSwift", 
            branch: "main"
        ),
        .package(
            url: "https://github.com/iCalvin-Actual/Blackbird", 
            branch: "main"
        ),
        .package(
            url: "https://github.com/iCalvin-Actual/MarkdownEditor.git", 
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "omgui",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "Punycode", package: "PunycodeSwift"),
                "Blackbird",
                "MarkdownEditor"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "omguiTests",
            dependencies: ["omgui"]),
    ]
)
