# SwiftMusicService

MusicKit does not work in the iOS Simulator. This package puts a small protocol layer between an app and MusicKit, so the app runs the same code against real MusicKit on a device and against an in-memory mock in the simulator. The mock returns placeholder playlists and songs and makes no sound.

## Installation

Requires iOS 26, macOS 26 or tvOS 26, and Swift 6.2.

```swift
dependencies: [
    .package(url: "https://github.com/drmarkpowell/SwiftMusicService.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "MusicService", package: "SwiftMusicService"),
            .product(name: "MusicServiceLive", package: "SwiftMusicService"),
        ]
    ),
]
```

Then `import MusicService` (and `import MusicServiceLive` where you create the service).

## Products

| Product | Imports MusicKit | Contents |
| --- | --- | --- |
| `MusicService` | No | Protocols, value types, `MusicArtworkView`, the mock |
| `MusicServiceLive` | Yes | `LiveMusicService` and `MusicServiceFactory` |

## Use

```swift
@State private var model = AppModel(service: MusicServiceFactory.makeDefault())
```

`makeDefault()` returns the mock in the simulator and MusicKit on a device. Launch arguments override it: `-MusicServiceUseMock` or `-MusicServiceUseLive`.

`MusicService` exposes four services:

- `authorization`: `currentStatus`, `request()`
- `catalog`: playlist lookup by id, playlist search, tracks of a playlist, tracks by id, `resolvePlaylist(name:urlString:)`
- `library`: find, create and edit library playlists (Favorites)
- `player`: an `@Observable` mirror of `ApplicationMusicPlayer` state and queue: status, shuffle, repeat, entries, current entry, playback time, play, pause, skip, seek, set queue

## The mock

`MockMusicService(behavior:data:)` keeps a real queue and clock. Shuffle, repeat, seeking, skipping and end-of-queue behave like `ApplicationMusicPlayer`.

`MockBehavior` is observable and shapes the mock at run time:

- `latency`: delay on every call
- `failures`: operations that throw `MusicServiceError.injected`
- `initialAuthorizationStatus`, `authorizationRequestResult`, `enforcesAuthorization`
- `autoAdvance`, `playbackSpeed`: the playback clock
- `seed`: shuffle order

In tests use `MockBehavior.instant()` and call `mockPlayer.advance(by:)` to move time.

`MockPlayerService.simulateStall()` clears the current entry while the status stays `.playing`. `MockLibraryService.seedReadOnlyPlaylist(name:tracks:)` makes a playlist that throws `.notEditable` when replaced.

## Differences from MusicKit

- Value types (`MusicTrack`, `MusicPlaylist`, `QueueEntry`) replace `Song`, `Playlist` and `Queue.Entry`. Artwork is a URL, or a gradient for the mock.
- Mock catalog search treats an empty term as "all playlists".
- On macOS the live library service throws `.unavailable`, because MusicKit has no `MusicLibrary` there.
- The live implementation compiles for iOS, macOS and tvOS but has not been run on a device.

## Demo and tests

```bash
swift test
open Example/MusicServiceDemo.xcodeproj
```

The demo has Browse, Now Playing (queue, scrubber, shuffle, repeat, favorite), Favorites and Behavior tabs. The Behavior tab changes latency, playback speed, authorization status and injected failures while the app runs.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
