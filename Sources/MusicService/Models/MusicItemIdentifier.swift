import Foundation

/// A stable identifier for a track or playlist, mirroring MusicKit's `MusicItemID`.
public struct MusicItemIdentifier: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String { rawValue }
}
