import Foundation

/// One slot in the player queue, mirroring `MusicPlayer.Queue.Entry`.
///
/// `id` is unique per slot, so the same track queued twice has two different entry ids.
public struct QueueEntry: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    /// The artist name for songs.
    public var subtitle: String?
    public var artwork: MusicArtwork?
    /// Length in seconds. Zero when unknown.
    public var duration: TimeInterval
    /// The song behind this entry, when it is a song.
    public var track: MusicTrack?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        artwork: MusicArtwork? = nil,
        duration: TimeInterval = 0,
        track: MusicTrack? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.artwork = artwork
        self.duration = duration
        self.track = track
    }

    public init(id: String, track: MusicTrack) {
        self.init(
            id: id,
            title: track.title,
            subtitle: track.artistName,
            artwork: track.artwork,
            duration: track.duration,
            track: track
        )
    }
}
