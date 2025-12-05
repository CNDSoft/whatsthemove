// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhatsTheMove",
    platforms: [
        .iOS(.v18),
        .macOS(.v12)
    ],
    products: [
        .library(name: "WhatsTheMove", targets: ["WhatsTheMove"])
    ],
    dependencies: [
        .package(url: "https://github.com/nalexn/EnvironmentOverrides", from: "0.0.4"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "WhatsTheMove",
            dependencies: [
                .product(name: "EnvironmentOverrides", package: "EnvironmentOverrides"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ],
            path: "WhatsTheMove",
            exclude: [
                "Resources/Preview Assets.xcassets",
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/Localizable.xcstrings"),
                .process("Resources/GoogleService-Info.plist"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("UIKit")
            ]
        ),
        .testTarget(
            name: "UnitTests",
            dependencies: [
                "WhatsTheMove",
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "UnitTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
        )
    ]
)
