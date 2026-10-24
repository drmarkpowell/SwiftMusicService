import Foundation
import Observation

/// Operations the mock can be told to fail.
public enum MockFailure: String, Hashable, Sendable, CaseIterable {
    case catalogLookup
    case catalogSearch
    case setQueue
    case play
    case skip
    case libraryRead
    case libraryWrite
}

/// Knobs that shape how the mock behaves. Observable, so a debug panel can change them live.
@Observable @MainActor
public final class MockBehavior {
    /// Delay applied to every asynchronous call, to exercise loading states.
    public var latency: Duration
    /// Operations that throw ``MusicServiceError/injected(_:)``.
    public var failures: Set<MockFailure>
    /// Whether catalog, library and player calls require authorization first.
    public var enforcesAuthorization: Bool
    public var initialAuthorizationStatus: MusicAuthorizationStatus
    /// What `request()` resolves to when the status is not yet determined.
    public var authorizationRequestResult: MusicAuthorizationStatus
    /// Whether a timer advances playback by itself. Turn off in tests and call `advance(by:)`.
    public var autoAdvance: Bool
    /// How many seconds of playback pass per real second. Raise it to reach the end of a song quickly.
    public var playbackSpeed: Double
    /// Seed for shuffling, so a given queue shuffles the same way every run.
    public var seed: UInt64
    /// When on, looking up an unknown playlist id or searching for an unknown name makes up a playlist
    /// with stable placeholder songs instead of finding nothing. Use it when the app's playlists come
    /// from its own data and cannot be listed in advance.
    public var generatesMissingPlaylists: Bool

    public init(
        latency: Duration = .milliseconds(200),
        failures: Set<MockFailure> = [],
        enforcesAuthorization: Bool = true,
        initialAuthorizationStatus: MusicAuthorizationStatus = .authorized,
        authorizationRequestResult: MusicAuthorizationStatus = .authorized,
        autoAdvance: Bool = true,
        playbackSpeed: Double = 1,
        seed: UInt64 = 42,
        generatesMissingPlaylists: Bool = false
    ) {
        self.latency = latency
        self.failures = failures
        self.enforcesAuthorization = enforcesAuthorization
        self.initialAuthorizationStatus = initialAuthorizationStatus
        self.authorizationRequestResult = authorizationRequestResult
        self.autoAdvance = autoAdvance
        self.playbackSpeed = playbackSpeed
        self.seed = seed
        self.generatesMissingPlaylists = generatesMissingPlaylists
    }

    /// No latency and no timer: every call completes immediately and time only moves when told to.
    public static func instant() -> MockBehavior {
        MockBehavior(latency: .zero, autoAdvance: false)
    }

    func simulateLatency() async throws {
        if latency > .zero {
            try await Task.sleep(for: latency)
        } else {
            try Task.checkCancellation()
        }
    }

    func check(_ failure: MockFailure) throws {
        if failures.contains(failure) {
            throw MusicServiceError.injected(failure.rawValue)
        }
    }
}
