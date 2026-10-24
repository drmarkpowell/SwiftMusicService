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
        return data.playlists.first { $0.id == id }
    }

    public func searchPlaylists(matching term: String, limit: Int) async throws -> [MusicPlaylist] {
        try await begin(.catalogSearch)
        // An empty term lists everything, which real catalog search does not do; it lets a
        // browse screen show the whole mock catalog.
        let matches = term.isEmpty ? data.playlists : data.playlists.filter { $0.name.localizedStandardContains(term) }
        return Array(matches.prefix(limit))
    }

    public func tracks(in playlist: MusicPlaylist) async throws -> [MusicTrack] {
        try await begin(.catalogLookup)
        guard let tracks = data.tracksByPlaylist[playlist.id] else {
            throw MusicServiceError.notFound
        }
        return tracks
    }

    public func tracks(ids: [MusicItemIdentifier]) async throws -> [MusicTrack] {
        try await begin(.catalogLookup)
        let known = Dictionary(data.allTracks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { known[$0] }
    }

    private func begin(_ failure: MockFailure) async throws {
        try authorization.requireAuthorized()
        try behavior.check(failure)
        try await behavior.simulateLatency()
    }
}
