// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "JobTracker",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "JobTracker",
            path: "Sources/JobTracker"
        )
    ]
)
