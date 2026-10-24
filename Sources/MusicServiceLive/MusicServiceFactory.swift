import MusicService

/// Chooses between MusicKit and the mock.
///
/// The simulator gets the mock because MusicKit does not work there; devices get MusicKit.
/// Two launch arguments override that: `-MusicServiceUseMock` forces the mock on a device
/// (handy for screenshots) and `-MusicServiceUseLive` forces MusicKit in the simulator.
public enum MusicServiceFactory {
    public enum Choice: Sendable {
        case live
        case mock
    }

    public static func preferredChoice(arguments: [String] = CommandLine.arguments) -> Choice {
        if arguments.contains("-MusicServiceUseMock") { return .mock }
        if arguments.contains("-MusicServiceUseLive") { return .live }
        #if targetEnvironment(simulator)
        return .mock
        #else
        return .live
        #endif
    }

    @MainActor
    public static func makeDefault(
        arguments: [String] = CommandLine.arguments,
        mockBehavior: MockBehavior = MockBehavior()
    ) -> any MusicService {
        switch preferredChoice(arguments: arguments) {
        case .live: LiveMusicService()
        case .mock: MockMusicService(behavior: mockBehavior)
        }
    }
}
