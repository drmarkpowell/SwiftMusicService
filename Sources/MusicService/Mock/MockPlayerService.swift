import Foundation
import Observation

/// A player that never makes a sound. It keeps a real queue, moves through songs on a
/// clock, and honors shuffle, repeat, seeking and skipping the way `ApplicationMusicPlayer` does.
@Observable @MainActor
public final class MockPlayerService: MusicPlayerService {
    public private(set) var playbackStatus: PlaybackStatus = .stopped
    public private(set) var entries: [QueueEntry] = []
    public private(set) var currentIndex: Int?

    public var shuffleMode: ShuffleMode = .off {
        didSet {
            if oldValue != shuffleMode { applyShuffleMode() }
        }
    }

    public var repeatMode: RepeatMode = .none

    /// Seconds into the current entry. Assigning seeks, clamped to the entry's length.
    public var playbackTime: TimeInterval = 0 {
        didSet {
            let upper = currentEntry?.duration ?? 0
            let clamped = min(max(playbackTime, 0), upper)
            if clamped != playbackTime { playbackTime = clamped }
        }
    }

    public var currentEntry: QueueEntry? {
        guard let currentIndex, entries.indices.contains(currentIndex) else { return nil }
        return entries[currentIndex]
    }

    @ObservationIgnored private let behavior: MockBehavior
    @ObservationIgnored private let authorization: MockAuthorizationService
    @ObservationIgnored private let loadTracks: @MainActor (MusicPlaylist) async throws -> [MusicTrack]
    @ObservationIgnored private var unshuffled: [QueueEntry] = []
    @ObservationIgnored private var generator: SeededGenerator
    @ObservationIgnored private var clock: Task<Void, Never>?

    /// How often the clock advances playback.
    private static let tickInterval = Duration.milliseconds(250)
    /// Skipping back after this many seconds restarts the song instead of going to the previous one.
    private static let restartThreshold: TimeInterval = 3

    public init(
        behavior: MockBehavior,
        authorization: MockAuthorizationService,
        loadTracks: @escaping @MainActor (MusicPlaylist) async throws -> [MusicTrack]
    ) {
        self.behavior = behavior
        self.authorization = authorization
        self.loadTracks = loadTracks
        self.generator = SeededGenerator(seed: behavior.seed)
    }

    // MARK: Transport

    public func play() async throws {
        try await begin(.play)
        guard !entries.isEmpty else { throw MusicServiceError.emptyQueue }
        if currentIndex == nil {
            currentIndex = 0
            playbackTime = 0
        }
        playbackStatus = .playing
        startClock()
    }

    public func pause() {
        guard playbackStatus == .playing else { return }
        playbackStatus = .paused
        stopClock()
    }

    public func stop() {
        playbackStatus = .stopped
        playbackTime = 0
        stopClock()
    }

    public func skipToNextEntry() async throws {
        try await begin(.skip)
        guard !entries.isEmpty else { throw MusicServiceError.emptyQueue }
        guard let index = currentIndex else {
            currentIndex = 0
            playbackTime = 0
            return
        }
        if index + 1 < entries.count {
            currentIndex = index + 1
            playbackTime = 0
        } else if repeatMode == .all {
            currentIndex = 0
            playbackTime = 0
        } else {
            endOfQueue()
        }
    }

    public func skipToPreviousEntry() async throws {
        try await begin(.skip)
        guard !entries.isEmpty else { throw MusicServiceError.emptyQueue }
        guard let index = currentIndex else {
            currentIndex = 0
            playbackTime = 0
            return
        }
        if playbackTime > Self.restartThreshold || index == 0 {
            playbackTime = 0
        } else {
            currentIndex = index - 1
            playbackTime = 0
        }
    }

    public func skip(to entry: QueueEntry) async throws {
        try await begin(.skip)
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else {
            throw MusicServiceError.notFound
        }
        guard index != currentIndex else { return }
        currentIndex = index
        playbackTime = 0
    }

    // MARK: Queue

    public func setQueue(playlist: MusicPlaylist) async throws {
        try await begin(.setQueue)
        let tracks = try await loadTracks(playlist)
        install(tracks)
    }

    public func setQueue(tracks: [MusicTrack]) async throws {
        try await begin(.setQueue)
        install(tracks)
    }

    // MARK: Simulation controls

    /// Moves playback forward by `seconds`, rolling into following entries as songs end.
    /// The clock calls this on a timer; tests call it directly with `autoAdvance` off.
    public func advance(by seconds: TimeInterval) {
        guard playbackStatus == .playing, seconds > 0, var entry = currentEntry, entry.duration > 0 else { return }
        var time = playbackTime + seconds
        while time >= entry.duration {
            let overflow = time - entry.duration
            guard finishCurrentEntry(), let next = currentEntry, next.duration > 0 else { return }
            entry = next
            time = overflow
        }
        playbackTime = time
    }

    /// Makes the queue lose its current entry while the status stays `.playing`, as MusicKit
    /// does when playback dies unexpectedly. Use it to exercise recovery UI.
    public func simulateStall() {
        currentIndex = nil
        playbackTime = 0
    }

    // MARK: Internals

    private func begin(_ failure: MockFailure) async throws {
        try authorization.requireAuthorized()
        try behavior.check(failure)
        try await behavior.simulateLatency()
    }

    private func install(_ tracks: [MusicTrack]) {
        var newEntries = tracks.enumerated().map { offset, track in
            QueueEntry(id: "\(track.id.rawValue)#\(offset)", track: track)
        }
        unshuffled = []
        if shuffleMode == .songs {
            unshuffled = newEntries
            newEntries.shuffle(using: &generator)
        }
        entries = newEntries
        currentIndex = newEntries.isEmpty ? nil : 0
        playbackTime = 0
        if playbackStatus != .playing { playbackStatus = .stopped }
    }

    private func applyShuffleMode() {
        let currentID = currentEntry?.id
        switch shuffleMode {
        case .songs:
            unshuffled = entries
            if let index = currentIndex {
                let head = Array(entries[...index])
                var tail = Array(entries[(index + 1)...])
                tail.shuffle(using: &generator)
                entries = head + tail
            } else {
                entries.shuffle(using: &generator)
            }
        case .off:
            guard !unshuffled.isEmpty else { return }
            entries = unshuffled
            unshuffled = []
            currentIndex = currentID.flatMap { id in entries.firstIndex { $0.id == id } }
        }
    }

    /// Returns true when playback moved on to another song (or restarted this one).
    private func finishCurrentEntry() -> Bool {
        if repeatMode == .one {
            playbackTime = 0
            return true
        }
        if let index = currentIndex, index + 1 < entries.count {
            currentIndex = index + 1
            playbackTime = 0
            return true
        }
        if repeatMode == .all, !entries.isEmpty {
            currentIndex = 0
            playbackTime = 0
            return true
        }
        endOfQueue()
        return false
    }

    private func endOfQueue() {
        playbackStatus = .stopped
        playbackTime = 0
        stopClock()
    }

    private func startClock() {
        guard behavior.autoAdvance, clock == nil else { return }
        clock = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.tickInterval)
                guard let self, !Task.isCancelled else { return }
                self.advance(by: 0.25 * self.behavior.playbackSpeed)
            }
        }
    }

    private func stopClock() {
        clock?.cancel()
        clock = nil
    }
}
