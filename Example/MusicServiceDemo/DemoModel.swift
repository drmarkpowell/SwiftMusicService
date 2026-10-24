import MusicService
import Observation

/// App state for the demo. All music access goes through `service`, never MusicKit.
@Observable @MainActor
final class DemoModel {
    static let favoritesName = "Demo Favorites"

    let service: any MusicService

    var searchText = ""
    var playlists: [MusicPlaylist] = []
    var isLoading = false
    var errorMessage: String?
    private(set) var favorites: [MusicTrack] = []

    @ObservationIgnored private var favoritesPlaylistID: MusicItemIdentifier?
    /// Bumped after an authorization request so views re-read a status that is not observable (live MusicKit).
    private var authorizationVersion = 0

    init(service: any MusicService) {
        self.service = service
    }

    var usingMock: Bool { service is MockMusicService }

    var authorizationStatus: MusicAuthorizationStatus {
        _ = authorizationVersion
        return service.authorization.currentStatus
    }

    var player: any MusicPlayerService { service.player }

    // MARK: Authorization

    func requestAuthorization() async {
        _ = await service.authorization.request()
        authorizationVersion += 1
    }

    // MARK: Browsing

    func search() async {
        isLoading = true
        defer { isLoading = false }
        do {
            playlists = try await service.catalog.searchPlaylists(matching: searchText, limit: 25)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func play(_ playlist: MusicPlaylist) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await player.play(playlist: playlist)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Transport

    func togglePlayPause() async {
        if player.isPlaying {
            player.pause()
        } else {
            await perform { try await player.play() }
        }
    }

    func skipToNext() async {
        await perform { try await player.skipToNextEntry() }
    }

    func skipToPrevious() async {
        await perform { try await player.skipToPreviousEntry() }
    }

    func skip(to entry: QueueEntry) async {
        await perform { try await player.skip(to: entry) }
    }

    func toggleShuffle() {
        player.shuffleMode = player.shuffleMode == .songs ? .off : .songs
    }

    func cycleRepeat() {
        switch player.repeatMode {
        case .none: player.repeatMode = .all
        case .all: player.repeatMode = .one
        case .one: player.repeatMode = .none
        }
    }

    // MARK: Favorites

    func isFavorite(_ track: MusicTrack) -> Bool {
        favorites.contains { $0.id == track.id }
    }

    func loadFavorites() async {
        await perform {
            guard let playlist = try await service.library.newestPlaylist(named: Self.favoritesName) else { return }
            favoritesPlaylistID = playlist.id
            favorites = try await service.library.tracks(inPlaylist: playlist.id)
        }
    }

    func toggleFavorite(_ track: MusicTrack) async {
        await perform {
            let playlistID = try await ensureFavoritesPlaylist()
            if isFavorite(track) {
                let remaining = favorites.filter { $0.id != track.id }
                do {
                    try await service.library.replaceTracks(in: playlistID, with: remaining)
                } catch MusicServiceError.notEditable {
                    // A playlist we did not create cannot be edited, so replace it with one we own.
                    let replacement = try await service.library.createPlaylist(
                        name: Self.favoritesName, description: nil, tracks: remaining
                    )
                    favoritesPlaylistID = replacement.id
                }
                favorites = remaining
            } else {
                try await service.library.add(track, to: playlistID)
                favorites.append(track)
            }
        }
    }

    func playFavorites() async {
        guard !favorites.isEmpty else { return }
        await perform { try await player.play(tracks: favorites) }
    }

    // MARK: Helpers

    private func ensureFavoritesPlaylist() async throws -> MusicItemIdentifier {
        if let favoritesPlaylistID { return favoritesPlaylistID }
        if let existing = try await service.library.newestPlaylist(named: Self.favoritesName) {
            favoritesPlaylistID = existing.id
            return existing.id
        }
        let created = try await service.library.createPlaylist(name: Self.favoritesName, description: nil, tracks: [])
        favoritesPlaylistID = created.id
        return created.id
    }

    private func perform(_ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
