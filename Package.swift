// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftMusicService",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
    ],
    products: [
        // Protocols, value types, SwiftUI helpers and the mock. Does not import MusicKit.
        .library(name: "MusicService", targets: ["MusicService"]),
        // The MusicKit-backed implementation, plus the factory that picks live or mock.
        .library(name: "MusicServiceLive", targets: ["MusicServiceLive"]),
    ],
    targets: [
        .target(name: "MusicService"),
        .target(name: "MusicServiceLive", dependencies: ["MusicService"]),
        .testTarget(name: "MusicServiceTests", dependencies: ["MusicService"]),
    ]
)
