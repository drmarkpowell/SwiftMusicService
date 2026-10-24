import Foundation

@MainActor
public final class MockCatalogService: MusicCatalogService {
    public var data: MockCatalogData

    private let behavior: MockBehavior
    private let authorization: MockAuthorizationService

    public init(data: MockCatalogData, behavior: MockBehavior, authorization: MockAuthorizationService) {
        self.data = data
        self.behavior = behavior
        self.authorization = authorization
    }

    public func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist? {
        try await begin(.catalogLookup)
        if let known = data.playlists.first(where: { $0.id == id }) { return known }
        guard behavior.generatesMissingPlaylists else { return nil }
        return generatePlaylist(id: id, name: "Mock Playlist \(id.rawValue.suffix(6))")
    }

    public func searchPlaylists(matching term: String, limit: Int) async throws -> [MusicPlaylist] {
        try await begin(.catalogSearch)
        // An empty term lists everything, which real catalog search does not do; it lets a
        // browse screen show the whole mock catalog.
        let matches = term.isEmpty ? data.playlists : data.playlists.filter { $0.name.localizedStandardContains(term) }
        if matches.isEmpty, !term.isEmpty, behavior.generatesMissingPlaylists {
            let slug = term.lowercased().replacing(" ", with: "-")
            return [generatePlaylist(id: MusicItemIdentifier("pl.mock.generated.\(slug)"), name: term)]
        }
        return Array(matches.prefix(limit))
    }

    public func tracks(in playlist: MusicPlaylist) async throws -> [MusicTrack] {
        try await begin(.catalogLookup)
        if let tracks = data.tracksByPlaylist[playlist.id] { return tracks }
        guard behavior.generatesMissingPlaylists else { throw MusicServiceError.notFound }
        return generatePlaylistTracks(for: playlist)
    }

    public func tracks(ids: [MusicItemIdentifier]) async throws -> [MusicTrack] {
        try await begin(.catalogLookup)
        let known = Dictionary(data.allTracks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { known[$0] }
    }

    /// Adds a made-up playlist to the catalog, once, so repeated lookups return the same one.
    private func generatePlaylist(id: MusicItemIdentifier, name: String) -> MusicPlaylist {
        if let existing = data.playlists.first(where: { $0.id == id }) { return existing }
        let seed = MockTrackGenerator.seed(for: id.rawValue)
        let playlist = MusicPlaylist(
            id: id,
            name: name,
            curatorName: "Mock Music",
            descriptionText: "Placeholder songs for \(name).",
            artwork: .placeholder(hue: Double(seed % 1000) / 1000),
            url: URL(string: "https://music.apple.com/us/playlist/mock/\(id.rawValue)"),
            source: .catalog
        )
        data.playlists.append(playlist)
        _ = generatePlaylistTracks(for: playlist)
        return playlist
    }

    private func generatePlaylistTracks(for playlist: MusicPlaylist) -> [MusicTrack] {
        let seed = MockTrackGenerator.seed(for: playlist.id.rawValue)
        let tracks = MockTrackGenerator.tracks(
            seed: seed,
            count: 8 + Int(seed % 5),
            hue: Double(seed % 1000) / 1000
        )
        data.tracksByPlaylist[playlist.id] = tracks
        return tracks
    }

    private func begin(_ failure: MockFailure) async throws {
        try authorization.requireAuthorized()
        try behavior.check(failure)
        try await behavior.simulateLatency()
    }
}
