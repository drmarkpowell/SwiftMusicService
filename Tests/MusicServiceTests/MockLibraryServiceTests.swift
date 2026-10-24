import Foundation
import Testing
@testable import MusicService

@MainActor
struct MockLibraryServiceTests {
    private let service = MockMusicService(behavior: .instant())

    private var songs: [MusicTrack] {
        Array(service.mockCatalog.data.allTracks.sorted { $0.id.rawValue < $1.id.rawValue }.prefix(3))
    }

    @Test func createdPlaylistsCanBeFoundByName() async throws {
        let created = try await service.library.createPlaylist(name: "DJ Mood Favorites", description: nil, tracks: [])
        let found = try await service.library.newestPlaylist(named: "DJ Mood Favorites")
        #expect(found?.id == created.id)
        #expect(created.source == .library)
    }

    @Test func newestPlaylistWinsWhenSeveralShareAName() async throws {
        var date = Date(timeIntervalSince1970: 1_000)
        let library = MockLibraryService(
            behavior: .instant(),
            authorization: MockAuthorizationService(behavior: .instant()),
            now: {
                date.addTimeInterval(60)
                return date
            }
        )
        _ = try await library.createPlaylist(name: "Dup", description: nil, tracks: [])
        let second = try await library.createPlaylist(name: "Dup", description: nil, tracks: [])

        #expect(try await library.newestPlaylist(named: "Dup")?.id == second.id)
    }

    @Test func addingAndLoadingTracksRoundTrips() async throws {
        let playlist = try await service.library.createPlaylist(name: "Mix", description: nil, tracks: [])
        for song in songs { try await service.library.add(song, to: playlist.id) }

        #expect(try await service.library.tracks(inPlaylist: playlist.id) == songs)
    }

    @Test func replacingTracksEditsAnAppCreatedPlaylist() async throws {
        let playlist = try await service.library.createPlaylist(name: "Mix", description: nil, tracks: songs)
        try await service.library.replaceTracks(in: playlist.id, with: Array(songs.dropFirst()))

        #expect(try await service.library.tracks(inPlaylist: playlist.id) == Array(songs.dropFirst()))
    }

    @Test func replacingTracksInAReadOnlyPlaylistThrows() async throws {
        let playlist = service.mockLibrary.seedReadOnlyPlaylist(name: "Old Favorites", tracks: songs)

        await #expect(throws: MusicServiceError.notEditable) {
            try await service.library.replaceTracks(in: playlist.id, with: [])
        }
        // Adding is still allowed, as with MusicKit.
        try await service.library.add(songs[0], to: playlist.id)
    }

    @Test func unknownPlaylistsThrowNotFound() async {
        await #expect(throws: MusicServiceError.notFound) {
            try await service.library.tracks(inPlaylist: "p.nope")
        }
    }

    @Test func libraryPlaylistsCanBePlayed() async throws {
        let playlist = try await service.library.createPlaylist(name: "Mix", description: nil, tracks: songs)
        try await service.player.play(playlist: playlist)

        #expect(service.player.entries.count == songs.count)
        #expect(service.player.isPlaying)
    }

    @Test func writeFailuresCanBeInjected() async {
        service.behavior.failures = [.libraryWrite]
        await #expect(throws: MusicServiceError.injected("libraryWrite")) {
            try await service.library.createPlaylist(name: "x", description: nil, tracks: [])
        }
    }
}
