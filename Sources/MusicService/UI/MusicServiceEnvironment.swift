import SwiftUI

private struct MusicServiceKey: EnvironmentKey {
    // The service is main-actor isolated and only read from views; `nil` carries no state.
    nonisolated(unsafe) static let defaultValue: (any MusicService)? = nil
}

public extension EnvironmentValues {
    /// The injected music service. `nil` until a parent calls ``SwiftUICore/View/musicService(_:)``.
    var musicService: (any MusicService)? {
        get { self[MusicServiceKey.self] }
        set { self[MusicServiceKey.self] = newValue }
    }
}

public extension View {
    func musicService(_ service: any MusicService) -> some View {
        environment(\.musicService, service)
    }
}
