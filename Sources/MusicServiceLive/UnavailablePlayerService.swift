#if os(watchOS)
import Foundation
import MusicService
import Observation

/// MusicKit has no player on watchOS, so this one plays nothing. Every attempt to start
/// playback throws ``MusicServiceError/unavailable``.
@Observable @MainActor
final class UnavailablePlayerService: MusicPlayerService {
    let playbackStatus = PlaybackStatus.stopped
    let entries: [QueueEntry] = []
    let currentEntry: QueueEntry? = nil

    var shuffleMode = ShuffleMode.off
    var repeatMode = RepeatMode.none
    var playbackTime: TimeInterval = 0

    func play() async throws { throw MusicServiceError.unavailable }
    func pause() {}
    func stop() {}
    func skipToNextEntry() async throws { throw MusicServiceError.unavailable }
    func skipToPreviousEntry() async throws { throw MusicServiceError.unavailable }
    func skip(to entry: QueueEntry) async throws { throw MusicServiceError.unavailable }
    func setQueue(playlist: MusicPlaylist) async throws { throw MusicServiceError.unavailable }
    func setQueue(tracks: [MusicTrack]) async throws { throw MusicServiceError.unavailable }
}
#endif
