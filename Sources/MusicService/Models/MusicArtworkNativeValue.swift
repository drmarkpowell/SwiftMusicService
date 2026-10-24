import Foundation

/// The framework's own artwork object, kept alongside the URL so a live view can draw it natively.
///
/// MusicKit artwork can use `musicKit://` URLs that only MusicKit's `ArtworkImage` can load, so a plain
/// image loader shows nothing for those. `MusicServiceLive` stores the `MusicKit.Artwork` here and draws it
/// with `ArtworkImage`. The mock leaves it empty.
public struct MusicArtworkNativeValue: Hashable, @unchecked Sendable {
    private let wrapped: AnyHashable

    public init(_ value: some Hashable & Sendable) {
        wrapped = AnyHashable(value)
    }

    /// The stored value, if it is a `T`.
    public func unwrap<T>(as type: T.Type) -> T? {
        wrapped.base as? T
    }
}
