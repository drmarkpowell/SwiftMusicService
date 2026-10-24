import Foundation

public enum MusicServiceError: LocalizedError, Equatable {
    case notAuthorized
    case notFound
    /// The playlist exists but this app is not allowed to edit it.
    case notEditable
    case emptyQueue
    /// The operation is not available on this platform.
    case unavailable
    /// A failure injected by the mock; the payload names which one.
    case injected(String)

    public var errorDescription: String? {
        switch self {
        case .notAuthorized: "Apple Music access has not been granted."
        case .notFound: "The requested item was not found."
        case .notEditable: "This playlist cannot be edited."
        case .emptyQueue: "The playback queue is empty."
        case .unavailable: "This operation is not available on this platform."
        case .injected(let name): "Injected failure: \(name)."
        }
    }
}
