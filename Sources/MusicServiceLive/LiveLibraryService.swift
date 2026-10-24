import Foundation
import MusicKit
import MusicService

/// Library access through `MusicLibrary`, which MusicKit offers on iOS and tvOS only.
/// On macOS every call throws ``MusicServiceError/unavailable``; DJ Mood's Mac build
/// keeps using its REST backend for Favorites.
@MainActor
final class LiveLibraryService: MusicLibraryService {
    private let store: MusicKitStore

    init(store: MusicKitStore) {
        self.store = store
    }

    #if os(macOS)

    func playlists(named name: String) async throws -> [MusicPlaylist] { throw MusicServiceError.unavailable }
    func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist? { throw MusicServiceError.unavailable }
    func createPlaylist(name: String, description: String?, tracks: [MusicTrack]) async throws -> MusicPlaylist {
        throw MusicServiceError.unavailable
    }
    func add(_ track: MusicTrack, to playlistID: MusicItemIdentifier) async throws {
        throw MusicServiceError.unavailable
    }
    func replaceTracks(in playlistID: MusicItemIdentifier, with tracks: [MusicTrack]) async throws {
        throw MusicServiceError.unavailable
    }
    func tracks(inPlaylist playlistID: MusicItemIdentifier) async throws -> [MusicTrack] {
        throw MusicServiceError.unavailable
    }

    #else

    func playlists(named name: String) async throws -> [MusicPlaylist] {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(text: name)
        let response = try await request.response()
        return response.items
            .filter { $0.name == name }
            .map { playlist in
                store.remember(playlist)
                return MusicPlaylist(playlist, source: .library)
            }
    }

    func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist? {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id.rawValue))
        guard let playlist = try await request.response().items.first else { return nil }
        store.remember(playlist)
        return MusicPlaylist(playlist, source: .library)
    }

    func createPlaylist(name: String, description: String?, tracks: [MusicTrack]) async throws -> MusicPlaylist {
        let songs = try await store.songs(for: tracks)
        let playlist = try await MusicLibrary.shared.createPlaylist(name: name, description: description, items: songs)
        store.remember(playlist)
        return MusicPlaylist(playlist, source: .library)
    }

    func add(_ track: MusicTrack, to playlistID: MusicItemIdentifier) async throws {
        guard let song = try await store.songs(for: [track]).first else { throw MusicServiceError.notFound }
        let playlist = try await libraryPlaylist(id: playlistID)
        try await MusicLibrary.shared.add(song, to: playlist)
    }

    func replaceTracks(in playlistID: MusicItemIdentifier, with tracks: [MusicTrack]) async throws {
        let songs = try await store.songs(for: tracks)
        let playlist = try await libraryPlaylist(id: playlistID)
        try await MusicLibrary.shared.edit(playlist, items: songs)
    }

    func tracks(inPlaylist playlistID: MusicItemIdentifier) async throws -> [MusicTrack] {
        let playlist = try await libraryPlaylist(id: playlistID)
        let detailed = try await playlist.with(.tracks)
        var result: [MusicTrack] = []
        var page = detailed.tracks
        while let current = page {
            for case .song(let song) in current {
                store.remember(song)
                result.append(MusicTrack(song))
            }
            page = current.hasNextBatch ? try await current.nextBatch() : nil
        }
        return result
    }

    private func libraryPlaylist(id: MusicItemIdentifier) async throws -> Playlist {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id.rawValue))
        guard let playlist = try await request.response().items.first else { throw MusicServiceError.notFound }
        return playlist
    }

    #endif
}
