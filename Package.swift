// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "swift-a11y-linter",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "swift-a11y-linter", targets: ["A11yLinter"])
    ],
    targets: [
        .executableTarget(
            name: "A11yLinter",
            path: "Sources/A11yLinter"
        ),
        .testTarget(
            name: "A11yLinterTests",
            dependencies: ["A11yLinter"],
            path: "Tests/A11yLinterTests"
        )
    ]
)
