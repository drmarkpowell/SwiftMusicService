/// The single entry point an app depends on instead of MusicKit.
///
/// Inject one instance (live or mock) at the root of the app and read the four
/// sub-services from it.
@MainActor
public protocol MusicService: AnyObject {
    var authorization: any MusicAuthorizationService { get }
    var catalog: any MusicCatalogService { get }
    var library: any MusicLibraryService { get }
    var player: any MusicPlayerService { get }
}
