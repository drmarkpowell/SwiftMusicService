/// Mirrors `MusicPlayer.PlaybackStatus`.
public enum PlaybackStatus: Hashable, Sendable {
    case stopped
    case playing
    case paused
    case interrupted
    case seekingForward
    case seekingBackward
}
