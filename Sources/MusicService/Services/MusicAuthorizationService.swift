/// Wraps `MusicAuthorization`.
@MainActor
public protocol MusicAuthorizationService: AnyObject {
    var currentStatus: MusicAuthorizationStatus { get }
    func request() async -> MusicAuthorizationStatus
}
