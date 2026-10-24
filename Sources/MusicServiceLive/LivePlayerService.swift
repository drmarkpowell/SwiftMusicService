#if !os(watchOS)
import Combine
import Foundation
@preconcurrency import MusicKit
import MusicService
import Observation

/// Mirrors `ApplicationMusicPlayer` into one `@Observable` object.
///
/// MusicKit publishes `state` and `queue` through Combine and exposes `playbackTime` only by
/// polling, so this class listens to both publishers and polls the time every 250 ms.
@Observable @MainActor
final class LivePlayerService: MusicPlayerService {
    private(set) var playbackStatus: PlaybackStatus = .stopped
    private(set) var entries: [QueueEntry] = []
    private(set) var currentEntry: QueueEntry?

    var shuffleMode: ShuffleMode = .off {
        didSet {
            guard !isRefreshing, oldValue != shuffleMode else { return }
            player.state.shuffleMode = shuffleMode == .songs ? .songs : .off
        }
    }

    var repeatMode: RepeatMode = .none {
        didSet {
            guard !isRefreshing, oldValue != repeatMode else { return }
            switch repeatMode {
            case .none: player.state.repeatMode = MusicPlayer.RepeatMode.none
            case .one: player.state.repeatMode = .one
            case .all: player.state.repeatMode = .all
            }
        }
    }

    var playbackTime: TimeInterval = 0 {
        didSet {
            guard !isRefreshing, oldValue != playbackTime else { return }
            player.playbackTime = playbackTime
        }
    }

    private var player: ApplicationMusicPlayer { ApplicationMusicPlayer.shared }
    @ObservationIgnored private let store: MusicKitStore
    @ObservationIgnored private var isRefreshing = false
    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    init(store: MusicKitStore) {
        self.store = store
        refreshAll()

        player.state.objectWillChange
            .merge(with: player.queue.objectWillChange)
            .sink { [weak self] _ in
                // objectWillChange fires before the change lands, so read on the next turn.
                Task { @MainActor [weak self] in self?.refreshAll() }
            }
            .store(in: &subscriptions)

        Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                self.refreshTime()
            }
        }
    }

    // MARK: Transport

    func play() async throws {
        try await player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.stop()
    }

    func skipToNextEntry() async throws {
        try await player.skipToNextEntry()
    }

    func skipToPreviousEntry() async throws {
        try await player.skipToPreviousEntry()
    }

    func skip(to entry: QueueEntry) async throws {
        guard let target = entries.firstIndex(where: { $0.id == entry.id }),
              let current = entries.firstIndex(where: { $0.id == currentEntry?.id })
        else { throw MusicServiceError.notFound }

        if target > current {
            for _ in 0..<(target - current) { try await player.skipToNextEntry() }
        } else if target < current {
            for _ in 0..<(current - target) { try await player.skipToPreviousEntry() }
        }
    }

    // MARK: Queue

    func setQueue(playlist: MusicPlaylist) async throws {
        let kitPlaylist = try await store.playlist(for: playlist)
        player.queue = [kitPlaylist]
    }

    func setQueue(tracks: [MusicTrack]) async throws {
        let songs = try await store.songs(for: tracks)
        guard !songs.isEmpty else { throw MusicServiceError.emptyQueue }
        player.queue = ApplicationMusicPlayer.Queue(for: songs)
    }

    // MARK: Mirroring

    private func refreshAll() {
        isRefreshing = true
        defer { isRefreshing = false }

        playbackStatus = PlaybackStatus(player.state.playbackStatus)
        shuffleMode = player.state.shuffleMode == .songs ? .songs : .off
        switch player.state.repeatMode {
        case .all: repeatMode = .all
        case .one: repeatMode = .one
        default: repeatMode = .none
        }

        let mappedEntries = player.queue.entries.map { entry -> QueueEntry in
            if case .song(let song)? = entry.item { store.remember(song) }
            return QueueEntry(entry)
        }
        if mappedEntries != entries { entries = mappedEntries }

        let mappedCurrent = player.queue.currentEntry.map { QueueEntry($0) }
        if mappedCurrent != currentEntry { currentEntry = mappedCurrent }

        playbackTime = player.playbackTime
    }

    private func refreshTime() {
        isRefreshing = true
        defer { isRefreshing = false }

        let status = PlaybackStatus(player.state.playbackStatus)
        if status != playbackStatus { playbackStatus = status }
        if player.queue.currentEntry?.id != currentEntry?.id {
            let mappedCurrent = player.queue.currentEntry.map { QueueEntry($0) }
            currentEntry = mappedCurrent
        }
        playbackTime = player.playbackTime
    }
}
#endif
