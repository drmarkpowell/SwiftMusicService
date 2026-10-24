import Foundation
import Observation

/// Wraps `ApplicationMusicPlayer`, its `state` and its `queue` in one observable object.
///
/// Conforming types must be `@Observable` so SwiftUI views update when any property changes.
@MainActor
public protocol MusicPlayerService: AnyObject, Observable {
    var playbackStatus: PlaybackStatus { get }
    var shuffleMode: ShuffleMode { get set }
    var repeatMode: RepeatMode { get set }

    var entries: [QueueEntry] { get }
    var currentEntry: QueueEntry? { get }

    /// Seconds into the current entry. Assigning seeks.
    var playbackTime: TimeInterval { get set }

    func play() async throws
    func pause()
    func stop()
    func skipToNextEntry() async throws
    func skipToPreviousEntry() async throws
    /// Jumps to an entry already in the queue.
    func skip(to entry: QueueEntry) async throws

    /// Replaces the queue with a playlist's songs. Call ``play()`` to start playback.
    func setQueue(playlist: MusicPlaylist) async throws
    /// Replaces the queue with these songs. Call ``play()`` to start playback.
    func setQueue(tracks: [MusicTrack]) async throws
}

public extension MusicPlayerService {
    func play(playlist: MusicPlaylist) async throws {
        try await setQueue(playlist: playlist)
        try await play()
    }

    func play(tracks: [MusicTrack]) async throws {
        try await setQueue(tracks: tracks)
        try await play()
    }

    var isPlaying: Bool { playbackStatus == .playing }
}
