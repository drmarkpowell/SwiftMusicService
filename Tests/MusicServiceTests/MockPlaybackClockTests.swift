import Testing
@testable import MusicService

@MainActor
struct MockPlaybackClockTests {
    @Test func theTimerMovesPlaybackWhenAutoAdvanceIsOn() async throws {
        let service = MockMusicService(
            behavior: MockBehavior(latency: .zero, autoAdvance: true, playbackSpeed: 40)
        )
        try await service.player.play(playlist: service.mockCatalog.data.playlists[0])

        try await Task.sleep(for: .milliseconds(700))

        #expect(service.mockPlayer.playbackTime > 0 || service.mockPlayer.currentIndex != 0)
        service.player.stop()
    }

    @Test func theTimerStaysOffWhenAutoAdvanceIsOff() async throws {
        let service = MockMusicService(behavior: .instant())
        try await service.player.play(playlist: service.mockCatalog.data.playlists[0])

        try await Task.sleep(for: .milliseconds(600))

        #expect(service.mockPlayer.playbackTime == 0)
    }
}
