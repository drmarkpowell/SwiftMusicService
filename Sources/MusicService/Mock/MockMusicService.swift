import Foundation

/// A complete in-memory stand-in for MusicKit that works in the simulator and in tests.
@MainActor
public final class MockMusicService: MusicService {
    public let behavior: MockBehavior
    public let mockAuthorization: MockAuthorizationService
    public let mockCatalog: MockCatalogService
    public let mockLibrary: MockLibraryService
    public let mockPlayer: MockPlayerService

    public var authorization: any MusicAuthorizationService { mockAuthorization }
    public var catalog: any MusicCatalogService { mockCatalog }
    public var library: any MusicLibraryService { mockLibrary }
    public var player: any MusicPlayerService { mockPlayer }

    public init(
        behavior: MockBehavior = MockBehavior(),
        data: MockCatalogData = .standard
    ) {
        let authorization = MockAuthorizationService(behavior: behavior)
        let catalog = MockCatalogService(data: data, behavior: behavior, authorization: authorization)
        let library = MockLibraryService(behavior: behavior, authorization: authorization)

        self.behavior = behavior
        self.mockAuthorization = authorization
        self.mockCatalog = catalog
        self.mockLibrary = library
        self.mockPlayer = MockPlayerService(behavior: behavior, authorization: authorization) { playlist in
            switch playlist.source {
            case .catalog:
                try await catalog.tracks(in: playlist)
            case .library:
                try await library.tracks(inPlaylist: playlist.id)
            }
        }
    }
}
