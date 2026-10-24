import Foundation
import Testing
@testable import MusicService

@MainActor
struct MockPlayerServiceTests {
    private let service = MockMusicService(behavior: .instant())

    private var player: MockPlayerService { service.mockPlayer }
    private var firstPlaylist: MusicPlaylist { service.mockCatalog.data.playlists[0] }

    private func startFirstPlaylist() async throws {
        try await player.play(playlist: firstPlaylist)
    }

    @Test func playingAPlaylistFillsTheQueueAndStartsTheFirstSong() async throws {
        try await startFirstPlaylist()

        let expected = service.mockCatalog.data.tracksByPlaylist[firstPlaylist.id] ?? []
        #expect(player.playbackStatus == .playing)
        #expect(player.entries.map { $0.track?.id } == expected.map(\.id))
        #expect(player.currentEntry?.track?.id == expected.first?.id)
        #expect(player.playbackTime == 0)
    }

    @Test func settingTheQueueDoesNotStartPlayback() async throws {
        try await player.setQueue(playlist: firstPlaylist)

        #expect(player.playbackStatus == .stopped)
        #expect(player.currentEntry != nil)
    }

    @Test func playWithAnEmptyQueueThrows() async {
        await #expect(throws: MusicServiceError.emptyQueue) {
            try await player.play()
        }
    }

    @Test func advancingMovesPlaybackTime() async throws {
        try await startFirstPlaylist()
        player.advance(by: 10)

        #expect(player.playbackTime == 10)
        #expect(player.currentIndex == 0)
    }

    @Test func advancingPastTheEndOfASongRollsIntoTheNextWithTheOverflow() async throws {
        try await startFirstPlaylist()
        let firstDuration = try #require(player.currentEntry?.duration)

        player.advance(by: firstDuration + 5)

        #expect(player.currentIndex == 1)
        #expect(player.playbackTime == 5)
    }

    @Test func pausedPlayerDoesNotAdvance() async throws {
        try await startFirstPlaylist()
        player.pause()
        player.advance(by: 30)

        #expect(player.playbackStatus == .paused)
        #expect(player.playbackTime == 0)
    }

    @Test func endOfQueueStopsPlaybackWhenNotRepeating() async throws {
        try await startFirstPlaylist()
        player.advance(by: 100_000)

        #expect(player.playbackStatus == .stopped)
        #expect(player.playbackTime == 0)
    }

    @Test func repeatAllWrapsToTheFirstSong() async throws {
        player.repeatMode = .all
        try await startFirstPlaylist()
        let total = player.entries.reduce(0) { $0 + $1.duration }

        player.advance(by: total + 1)

        #expect(player.playbackStatus == .playing)
        #expect(player.currentIndex == 0)
        #expect(player.playbackTime == 1)
    }

    @Test func repeatOneReplaysTheSameSong() async throws {
        player.repeatMode = .one
        try await startFirstPlaylist()
        let duration = try #require(player.currentEntry?.duration)

        player.advance(by: duration + 2)

        #expect(player.currentIndex == 0)
        #expect(player.playbackTime == 2)
    }

    @Test func skippingBackLateInASongRestartsIt() async throws {
        try await startFirstPlaylist()
        try await player.skipToNextEntry()
        player.advance(by: 10)

        try await player.skipToPreviousEntry()

        #expect(player.currentIndex == 1)
        #expect(player.playbackTime == 0)
    }

    @Test func skippingBackEarlyGoesToThePreviousSong() async throws {
        try await startFirstPlaylist()
        try await player.skipToNextEntry()
        player.advance(by: 1)

        try await player.skipToPreviousEntry()

        #expect(player.currentIndex == 0)
    }

    @Test func skippingNextAtTheEndStopsUnlessRepeatingAll() async throws {
        try await startFirstPlaylist()
        for _ in player.entries.indices.dropFirst() { try await player.skipToNextEntry() }
        try await player.skipToNextEntry()
        #expect(player.playbackStatus == .stopped)

        player.repeatMode = .all
        try await player.play()
        try await player.skipToNextEntry()
        #expect(player.currentIndex == 0)
        #expect(player.playbackStatus == .playing)
    }

    @Test func skipToEntryJumpsDirectly() async throws {
        try await startFirstPlaylist()
        let target = player.entries[4]

        try await player.skip(to: target)

        #expect(player.currentEntry?.id == target.id)
        #expect(player.playbackTime == 0)
    }

    @Test func seekingClampsToTheSongLength() async throws {
        try await startFirstPlaylist()
        let duration = try #require(player.currentEntry?.duration)

        player.playbackTime = duration + 500
        #expect(player.playbackTime == duration)

        player.playbackTime = -5
        #expect(player.playbackTime == 0)
    }

    @Test func shufflingKeepsTheSameSongsAndTheCurrentOneFirst() async throws {
        try await startFirstPlaylist()
        let original = player.entries
        let current = try #require(player.currentEntry)

        player.shuffleMode = .songs

        #expect(Set(player.entries.map(\.id)) == Set(original.map(\.id)))
        #expect(player.entries.map(\.id) != original.map(\.id))
        #expect(player.currentEntry?.id == current.id)
    }

    @Test func turningShuffleOffRestoresTheOriginalOrderAroundTheCurrentSong() async throws {
        try await startFirstPlaylist()
        let original = player.entries
        player.shuffleMode = .songs
        try await player.skipToNextEntry()
        let current = try #require(player.currentEntry)

        player.shuffleMode = .off

        #expect(player.entries == original)
        #expect(player.currentEntry?.id == current.id)
    }

    @Test func shuffleIsRepeatableForTheSameSeed() async throws {
        let other = MockMusicService(behavior: .instant())
        for service in [service, other] {
            service.mockPlayer.shuffleMode = .songs
            try await service.mockPlayer.setQueue(playlist: service.mockCatalog.data.playlists[0])
        }

        #expect(player.entries.map(\.id) == other.mockPlayer.entries.map(\.id))
    }

    @Test func stallingClearsTheCurrentEntryButNotTheStatus() async throws {
        try await startFirstPlaylist()
        player.simulateStall()

        #expect(player.currentEntry == nil)
        #expect(player.playbackStatus == .playing)

        try await player.play()
        #expect(player.currentEntry != nil)
    }

    @Test func injectedFailuresThrow() async throws {
        service.behavior.failures = [.play]
        try await player.setQueue(playlist: firstPlaylist)

        await #expect(throws: MusicServiceError.injected("play")) {
            try await player.play()
        }
        #expect(player.playbackStatus == .stopped)
    }

    @Test func playingWithoutAuthorizationThrows() async throws {
        service.mockAuthorization.setStatus(.denied)

        await #expect(throws: MusicServiceError.notAuthorized) {
            try await player.setQueue(playlist: firstPlaylist)
        }
    }

    @Test func stopResetsTime() async throws {
        try await startFirstPlaylist()
        player.advance(by: 20)
        player.stop()

        #expect(player.playbackStatus == .stopped)
        #expect(player.playbackTime == 0)
    }
}
