import MusicKit
import MusicService

@MainActor
final class LiveCatalogService: MusicCatalogService {
    private let store: MusicKitStore

    init(store: MusicKitStore) {
        self.store = store
    }

    func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist? {
        var request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(id.rawValue))
        request.limit = 1
        guard let playlist = try await request.response().items.first else { return nil }
        store.remember(playlist)
        return MusicPlaylist(playlist, source: .catalog)
    }

    func searchPlaylists(matching term: String, limit: Int) async throws -> [MusicPlaylist] {
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = limit
        let playlists = try await request.response().playlists
        for playlist in playlists { store.remember(playlist) }
        return playlists.map { MusicPlaylist($0, source: .catalog) }
    }

    func tracks(in playlist: MusicPlaylist) async throws -> [MusicTrack] {
        let kitPlaylist = try await store.playlist(for: playlist)
        let detailed = try await kitPlaylist.with(.tracks)
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

    func tracks(ids: [MusicItemIdentifier]) async throws -> [MusicTrack] {
        var result: [MusicTrack] = []
        // The catalog accepts a limited number of ids per request.
        for chunk in stride(from: 0, to: ids.count, by: 100).map({ Array(ids[$0..<min($0 + 100, ids.count)]) }) {
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                memberOf: chunk.map { MusicItemID($0.rawValue) }
            )
            for song in try await request.response().items {
                store.remember(song)
                result.append(MusicTrack(song))
            }
        }
        return result
    }
}
