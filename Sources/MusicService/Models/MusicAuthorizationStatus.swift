/// Mirrors `MusicAuthorization.Status`.
public enum MusicAuthorizationStatus: Hashable, Sendable {
    case notDetermined
    case denied
    case restricted
    case authorized
}
