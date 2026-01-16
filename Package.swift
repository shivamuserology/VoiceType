// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VoiceType",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoiceType", targets: ["VoiceType"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.8.0"),
        .package(url: "https://github.com/google/generative-ai-swift", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "VoiceType",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ],
            path: "VoiceType"
        )
    ]
)
