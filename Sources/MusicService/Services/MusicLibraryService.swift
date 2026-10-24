import Foundation

/// Wraps the user's music library: the operations DJ Mood's Favorites feature needs.
@MainActor
public protocol MusicLibraryService: AnyObject {
    /// Library playlists whose name matches `name` exactly.
    func playlists(named name: String) async throws -> [MusicPlaylist]

    func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist?

    func createPlaylist(name: String, description: String?, tracks: [MusicTrack]) async throws -> MusicPlaylist

    func add(_ track: MusicTrack, to playlistID: MusicItemIdentifier) async throws

    /// Replaces the contents of a playlist. Throws ``MusicServiceError/notEditable`` for a
    /// playlist this app did not create.
    func replaceTracks(in playlistID: MusicItemIdentifier, with tracks: [MusicTrack]) async throws

    /// All songs in a library playlist, following pagination.
    func tracks(inPlaylist playlistID: MusicItemIdentifier) async throws -> [MusicTrack]
}

public extension MusicLibraryService {
    /// The most recently added playlist with this name, if any.
    func newestPlaylist(named name: String) async throws -> MusicPlaylist? {
        try await playlists(named: name).max {
            ($0.addedDate ?? .distantPast) < ($1.addedDate ?? .distantPast)
        }
    }
}
