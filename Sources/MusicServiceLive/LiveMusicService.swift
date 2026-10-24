import MusicService

/// The real thing: every call goes to MusicKit.
@MainActor
public final class LiveMusicService: MusicService {
    public let authorization: any MusicAuthorizationService
    public let catalog: any MusicCatalogService
    public let library: any MusicLibraryService
    public let player: any MusicPlayerService

    public init() {
        let store = MusicKitStore()
        authorization = LiveAuthorizationService()
        catalog = LiveCatalogService(store: store)
        library = LiveLibraryService(store: store)
        player = LivePlayerService(store: store)
    }
}
