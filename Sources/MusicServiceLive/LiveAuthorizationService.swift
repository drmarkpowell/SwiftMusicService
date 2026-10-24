import MusicKit
import MusicService

@MainActor
final class LiveAuthorizationService: MusicAuthorizationService {
    var currentStatus: MusicAuthorizationStatus {
        MusicAuthorizationStatus(MusicAuthorization.currentStatus)
    }

    func request() async -> MusicAuthorizationStatus {
        MusicAuthorizationStatus(await MusicAuthorization.request())
    }
}
