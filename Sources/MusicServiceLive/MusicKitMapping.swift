import Foundation
import MusicKit
import MusicService

// Conversions from MusicKit types to the package's value types.

extension MusicArtwork {
    init?(_ artwork: Artwork?) {
        guard let artwork else { return nil }
        self.init(
            url: artwork.url(width: 600, height: 600),
            hue: 0.6,
            native: MusicArtworkNativeValue(artwork)
        )
    }
}

extension MusicTrack {
    init(_ song: Song) {
        self.init(
            id: MusicItemIdentifier(song.id.rawValue),
            title: song.title,
            artistName: song.artistName,
            albumTitle: song.albumTitle,
            duration: song.duration ?? 0,
            artwork: MusicArtwork(song.artwork),
            url: song.url
        )
    }
}

extension MusicPlaylist {
    init(_ playlist: Playlist, source: Source) {
        self.init(
            id: MusicItemIdentifier(playlist.id.rawValue),
            name: playlist.name,
            curatorName: playlist.curatorName,
            descriptionText: playlist.standardDescription,
            artwork: MusicArtwork(playlist.artwork),
            url: playlist.url,
            source: source,
            addedDate: playlist.libraryAddedDate
        )
    }
}

#if !os(watchOS)

extension QueueEntry {
    init(_ entry: ApplicationMusicPlayer.Queue.Entry) {
        var track: MusicTrack?
        if case .song(let song)? = entry.item {
            track = MusicTrack(song)
        }
        self.init(
            id: entry.id,
            title: entry.title,
            subtitle: entry.subtitle,
            artwork: MusicArtwork(entry.artwork),
            duration: track?.duration ?? 0,
            track: track
        )
    }
}

extension PlaybackStatus {
    init(_ status: MusicPlayer.PlaybackStatus) {
        switch status {
        case .stopped: self = .stopped
        case .playing: self = .playing
        case .paused: self = .paused
        case .interrupted: self = .interrupted
        case .seekingForward: self = .seekingForward
        case .seekingBackward: self = .seekingBackward
        @unknown default: self = .stopped
        }
    }
}

#endif

extension MusicAuthorizationStatus {
    init(_ status: MusicAuthorization.Status) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .restricted: self = .restricted
        case .authorized: self = .authorized
        @unknown default: self = .notDetermined
        }
    }
}
