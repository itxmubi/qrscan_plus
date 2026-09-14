// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "qrscan_plus",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "qrscan-plus", targets: ["qrscan_plus"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "qrscan_plus",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
