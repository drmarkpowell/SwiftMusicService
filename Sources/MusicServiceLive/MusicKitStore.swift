import Foundation
import MusicKit
import MusicService

/// Remembers the MusicKit `Song` and `Playlist` objects behind the package's value types,
/// because the player can only queue MusicKit items, not our copies of them.
@MainActor
final class MusicKitStore {
    private var songs: [MusicItemIdentifier: Song] = [:]
    private var playlists: [MusicItemIdentifier: Playlist] = [:]

    func remember(_ song: Song) {
        songs[MusicItemIdentifier(song.id.rawValue)] = song
    }

    func remember(_ playlist: Playlist) {
        playlists[MusicItemIdentifier(playlist.id.rawValue)] = playlist
    }

    /// The MusicKit songs for these tracks, fetching any that were never seen.
    func songs(for tracks: [MusicTrack]) async throws -> [Song] {
        let missing = tracks.map(\.id).filter { songs[$0] == nil }
        if !missing.isEmpty {
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                memberOf: missing.map { MusicItemID($0.rawValue) }
            )
            for song in try await request.response().items { remember(song) }
        }
        return tracks.compactMap { songs[$0.id] }
    }

    /// The MusicKit playlist for this value, fetching it if it was never seen.
    func playlist(for playlist: MusicPlaylist) async throws -> Playlist {
        if let known = playlists[playlist.id] { return known }

        let id = MusicItemID(playlist.id.rawValue)
        var found: Playlist?
        switch playlist.source {
        case .catalog:
            let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: id)
            found = try await request.response().items.first
        case .library:
            #if os(macOS)
            throw MusicServiceError.unavailable
            #else
            var request = MusicLibraryRequest<Playlist>()
            request.filter(matching: \.id, equalTo: id)
            found = try await request.response().items.first
            #endif
        }
        guard let found else { throw MusicServiceError.notFound }
        remember(found)
        return found
    }
}
