import Testing
@testable import MusicService

@MainActor
struct MockAuthorizationServiceTests {
    @Test func startsWithTheConfiguredStatus() {
        let service = MockMusicService(behavior: MockBehavior(initialAuthorizationStatus: .denied))
        #expect(service.authorization.currentStatus == .denied)
    }

    @Test func requestingResolvesAnUndeterminedStatus() async {
        let service = MockMusicService(
            behavior: MockBehavior(
                latency: .zero,
                initialAuthorizationStatus: .notDetermined,
                authorizationRequestResult: .authorized
            )
        )

        let status = await service.authorization.request()

        #expect(status == .authorized)
        #expect(service.authorization.currentStatus == .authorized)
    }

    @Test func requestingKeepsADeniedStatus() async {
        let service = MockMusicService(
            behavior: MockBehavior(
                latency: .zero,
                initialAuthorizationStatus: .denied,
                authorizationRequestResult: .authorized
            )
        )
        #expect(await service.authorization.request() == .denied)
    }

    @Test func catalogCallsFailUntilAuthorized() async {
        let service = MockMusicService(
            behavior: MockBehavior(latency: .zero, initialAuthorizationStatus: .notDetermined)
        )
        await #expect(throws: MusicServiceError.notAuthorized) {
            try await service.catalog.searchPlaylists(matching: "x", limit: 1)
        }
    }

    @Test func enforcementCanBeSwitchedOff() async throws {
        let service = MockMusicService(
            behavior: MockBehavior(latency: .zero, enforcesAuthorization: false, initialAuthorizationStatus: .denied)
        )
        _ = try await service.catalog.searchPlaylists(matching: "x", limit: 1)
    }
}
