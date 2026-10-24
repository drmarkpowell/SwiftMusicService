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
