import Foundation
import Testing
@testable import MusicService

@MainActor
struct MockCatalogServiceTests {
    private let service = MockMusicService(behavior: .instant())

    @Test func lookupByIDFindsThePlaylist() async throws {
        let expected = service.mockCatalog.data.playlists[2]
        let found = try await service.catalog.playlist(id: expected.id)
        #expect(found == expected)
    }

    @Test func lookupOfAnUnknownIDReturnsNil() async throws {
        #expect(try await service.catalog.playlist(id: "pl.nope") == nil)
    }

    @Test func searchMatchesNamesIgnoringCaseAndHonorsTheLimit() async throws {
        let results = try await service.catalog.searchPlaylists(matching: "feeling", limit: 5)
        #expect(results.map(\.name) == ["Feeling Good"])

        let limited = try await service.catalog.searchPlaylists(matching: "i", limit: 2)
        #expect(limited.count == 2)
    }

    @Test func anEmptySearchTermListsTheWholeMockCatalog() async throws {
        let results = try await service.catalog.searchPlaylists(matching: "", limit: 50)
        #expect(results == service.mockCatalog.data.playlists)
    }

    @Test func resolvingPrefersTheIDInTheURL() async throws {
        let target = service.mockCatalog.data.playlists[3]
        let url = try #require(target.url)

        let resolved = try await service.catalog.resolvePlaylist(name: "Chill Vibes", urlString: url.absoluteString)

        #expect(resolved == target)
    }

    @Test func resolvingFallsBackToNameWhenTheURLHasNoCatalogID() async throws {
        let resolved = try await service.catalog.resolvePlaylist(
            name: "Chill Vibes",
            urlString: "https://example.com/not-a-playlist"
        )
        #expect(resolved?.name == "Chill Vibes")
    }

    @Test func tracksComeBackInPlaylistOrder() async throws {
        let playlist = service.mockCatalog.data.playlists[0]
        let tracks = try await service.catalog.tracks(in: playlist)
        #expect(tracks == service.mockCatalog.data.tracksByPlaylist[playlist.id])
    }

    @Test func tracksByIDSkipUnknownIDs() async throws {
        let known = try #require(service.mockCatalog.data.allTracks.first)
        let tracks = try await service.catalog.tracks(ids: [known.id, "i.nope"])
        #expect(tracks == [known])
    }

    @Test func unknownPlaylistsAreNotFoundByDefault() async throws {
        #expect(try await service.catalog.playlist(id: "pl.u-unknown") == nil)
        #expect(try await service.catalog.searchPlaylists(matching: "Nothing Like This", limit: 1).isEmpty)
    }

    @Test func missingPlaylistsCanBeGeneratedByID() async throws {
        let service = MockMusicService(behavior: MockBehavior(latency: .zero, generatesMissingPlaylists: true))

        let playlist = try #require(try await service.catalog.playlist(id: "pl.u-8e5Ek2Vwr9"))
        let tracks = try await service.catalog.tracks(in: playlist)

        #expect((8...12).contains(tracks.count))
        #expect(try await service.catalog.playlist(id: "pl.u-8e5Ek2Vwr9") == playlist)
        #expect(try await service.catalog.tracks(in: playlist) == tracks)
    }

    @Test func missingPlaylistsCanBeGeneratedByName() async throws {
        let service = MockMusicService(behavior: MockBehavior(latency: .zero, generatesMissingPlaylists: true))

        let resolved = try await service.catalog.resolvePlaylist(name: "Feeling Angry", urlString: nil)

        #expect(resolved?.name == "Feeling Angry")
    }

    @Test func generatedSongsAreTheSameInEveryService() async throws {
        let first = MockMusicService(behavior: MockBehavior(latency: .zero, generatesMissingPlaylists: true))
        let second = MockMusicService(behavior: MockBehavior(latency: .zero, generatesMissingPlaylists: true))

        let firstPlaylist = try #require(try await first.catalog.playlist(id: "pl.u-abc"))
        let secondPlaylist = try #require(try await second.catalog.playlist(id: "pl.u-abc"))

        #expect(try await first.catalog.tracks(in: firstPlaylist) == second.catalog.tracks(in: secondPlaylist))
    }

    @Test func generatedPlaylistsCanBePlayed() async throws {
        let behavior = MockBehavior(latency: .zero, autoAdvance: false, generatesMissingPlaylists: true)
        let service = MockMusicService(behavior: behavior)
        let url = "https://music.apple.com/us/playlist/x/pl.u-xyz"
        let playlist = try #require(try await service.catalog.resolvePlaylist(name: "Chill", urlString: url))

        try await service.player.play(playlist: playlist)

        #expect(service.player.isPlaying)
        #expect(!service.player.entries.isEmpty)
    }

    @Test func searchFailureCanBeInjected() async {
        service.behavior.failures = [.catalogSearch]
        await #expect(throws: MusicServiceError.injected("catalogSearch")) {
            try await service.catalog.searchPlaylists(matching: "x", limit: 1)
        }
    }

    @Test func slowResponsesCanBeCancelled() async {
        service.behavior.latency = .seconds(30)
        let catalog = service.catalog
        let task = Task { @MainActor in
            try await catalog.searchPlaylists(matching: "Feeling", limit: 1)
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
