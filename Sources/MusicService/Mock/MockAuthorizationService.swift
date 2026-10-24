import Observation

@Observable @MainActor
public final class MockAuthorizationService: MusicAuthorizationService {
    public private(set) var currentStatus: MusicAuthorizationStatus

    @ObservationIgnored private let behavior: MockBehavior

    public init(behavior: MockBehavior) {
        self.behavior = behavior
        self.currentStatus = behavior.initialAuthorizationStatus
    }

    public func request() async -> MusicAuthorizationStatus {
        try? await behavior.simulateLatency()
        if currentStatus == .notDetermined {
            currentStatus = behavior.authorizationRequestResult
        }
        return currentStatus
    }

    /// Forces a status, as if the user changed it in Settings.
    public func setStatus(_ status: MusicAuthorizationStatus) {
        currentStatus = status
    }

    func requireAuthorized() throws {
        if behavior.enforcesAuthorization, currentStatus != .authorized {
            throw MusicServiceError.notAuthorized
        }
    }
}
