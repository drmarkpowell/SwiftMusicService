import Foundation
import Observation

/// An in-memory library. Playlists created through the service are editable; playlists
/// passed to `init` or marked with ``markReadOnly(_:)`` throw ``MusicServiceError/notEditable``
/// when replaced, like playlists another app created.
@Observable @MainActor
public final class MockLibraryService: MusicLibraryService {
    public private(set) var playlistsByID: [MusicItemIdentifier: MusicPlaylist] = [:]
    public private(set) var tracksByPlaylistID: [MusicItemIdentifier: [MusicTrack]] = [:]

    @ObservationIgnored private var readOnlyIDs: Set<MusicItemIdentifier> = []
    @ObservationIgnored private var nextNumber = 1
    @ObservationIgnored private let behavior: MockBehavior
    @ObservationIgnored private let authorization: MockAuthorizationService
    @ObservationIgnored private let now: @MainActor () -> Date

    public init(
        behavior: MockBehavior,
        authorization: MockAuthorizationService,
        now: @escaping @MainActor () -> Date = { Date() }
    ) {
        self.behavior = behavior
        self.authorization = authorization
        self.now = now
    }

    /// Adds a playlist this app is not allowed to edit.
    @discardableResult
    public func seedReadOnlyPlaylist(name: String, tracks: [MusicTrack] = []) -> MusicPlaylist {
        let playlist = insert(name: name, description: nil, tracks: tracks)
        readOnlyIDs.insert(playlist.id)
        return playlist
    }

    public func markReadOnly(_ playlistID: MusicItemIdentifier) {
        readOnlyIDs.insert(playlistID)
    }

    public func playlists(named name: String) async throws -> [MusicPlaylist] {
        try await begin(.libraryRead)
        return playlistsByID.values.filter { $0.name == name }
    }

    public func playlist(id: MusicItemIdentifier) async throws -> MusicPlaylist? {
        try await begin(.libraryRead)
        return playlistsByID[id]
    }

    public func createPlaylist(name: String, description: String?, tracks: [MusicTrack]) async throws -> MusicPlaylist {
        try await begin(.libraryWrite)
        return insert(name: name, description: description, tracks: tracks)
    }

    public func add(_ track: MusicTrack, to playlistID: MusicItemIdentifier) async throws {
        try await begin(.libraryWrite)
        guard tracksByPlaylistID[playlistID] != nil else { throw MusicServiceError.notFound }
        tracksByPlaylistID[playlistID, default: []].append(track)
    }

    public func replaceTracks(in playlistID: MusicItemIdentifier, with tracks: [MusicTrack]) async throws {
        try await begin(.libraryWrite)
        guard tracksByPlaylistID[playlistID] != nil else { throw MusicServiceError.notFound }
        guard !readOnlyIDs.contains(playlistID) else { throw MusicServiceError.notEditable }
        tracksByPlaylistID[playlistID] = tracks
    }

    public func tracks(inPlaylist playlistID: MusicItemIdentifier) async throws -> [MusicTrack] {
        try await begin(.libraryRead)
        guard let tracks = tracksByPlaylistID[playlistID] else { throw MusicServiceError.notFound }
        return tracks
    }

    private func insert(name: String, description: String?, tracks: [MusicTrack]) -> MusicPlaylist {
        let playlist = MusicPlaylist(
            id: MusicItemIdentifier("p.mock.\(nextNumber)"),
            name: name,
            descriptionText: description,
            artwork: .placeholder(hue: 0.95),
            source: .library,
            addedDate: now()
        )
        nextNumber += 1
        playlistsByID[playlist.id] = playlist
        tracksByPlaylistID[playlist.id] = tracks
        return playlist
    }

    private func begin(_ failure: MockFailure) async throws {
        try authorization.requireAuthorized()
        try behavior.check(failure)
        try await behavior.simulateLatency()
    }
}
