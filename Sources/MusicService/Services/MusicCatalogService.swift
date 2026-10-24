import Foundation

/// Wraps the Apple Music catalog requests.
@MainActor
public protocol MusicCatalogService: AnyObject {
    /// Looks up a catalog playlist by id. Returns `nil` when there is no match.
    func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist?

    func searchPlaylists(matching term: String, limit: Int) async throws -> [MusicPlaylist]

    /// All songs in a playlist, following pagination.
    func tracks(in playlist: MusicPlaylist) async throws -> [MusicTrack]

    /// Songs by id. Ids that cannot be found are left out.
    func tracks(ids: [MusicItemIdentifier]) async throws -> [MusicTrack]
}

public extension MusicCatalogService {
    /// Finds a playlist the way DJ Mood does: by the id at the end of its Apple Music URL
    /// when that id looks like a catalog playlist id (`pl.…`), otherwise by name search.
    func resolvePlaylist(name: String, urlString: String? = nil) async throws -> MusicPlaylist? {
        if let urlString, let url = URL(string: urlString) {
            let identifier = url.lastPathComponent
            if identifier.hasPrefix("pl."),
               let playlist = try await playlist(id: MusicItemIdentifier(identifier)) {
                return playlist
            }
        }
        return try await searchPlaylists(matching: name, limit: 1).first
    }
}
