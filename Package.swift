// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NewtonCoach",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "NewtonCoachCore",
            targets: ["NewtonCoachCore"]
        ),
    ],
    targets: [
        .target(
            name: "NewtonCoachCore",
            path: "NewtonCoach"
        )
    ]
)
