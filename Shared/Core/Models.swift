import Foundation

public enum SessionState: String, Codable, Sendable { case preparing, active, completed, endedEarly, failed }
public struct FocusSession: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public var state: SessionState
    public var finishedAt: Date?
    public var failure: String?
    public let simulated: Bool
    public init(id: UUID = UUID(), start: Date, end: Date, state: SessionState = .preparing, simulated: Bool) {
        self.id = id; self.start = start; self.end = end; self.state = state; self.simulated = simulated
    }
    public var isPending: Bool { state == .active || state == .preparing }
    public var duration: TimeInterval { end.timeIntervalSince(start) }
    public var storeName: String { "unscroll.focus" }
    public func remaining(at date: Date) -> TimeInterval { max(0, end.timeIntervalSince(date)) }
    public func progress(at date: Date) -> Double { min(1, max(0, 1 - remaining(at: date) / max(1, duration))) }
}
public enum AccessState: String, Sendable { case notDetermined, approved, denied, revoked, restricted, unavailable }
public enum FocusError: LocalizedError {
    case permission, emptySelection, overlapping, invalidDuration, persistence(String), configuration(String), shielding
    public var errorDescription: String? {
        switch self {
        case .permission: "Screen Time access is required. Review permission in Settings."
        case .emptySelection: "Choose at least one app, category, or website first."
        case .overlapping: "A focus session is already running. End it before starting another."
        case .invalidDuration: "Choose a duration between 15 and 720 minutes."
        case .persistence(let reason): "Local storage could not be updated: \(reason)"
        case .configuration(let reason): reason
        case .shielding: "Apple’s restriction settings could not be applied. No session was started."
        }
    }
}
public struct SelectionCounts: Equatable, Sendable {
    public var apps: Int; public var categories: Int; public var websites: Int
    public init(apps: Int = 0, categories: Int = 0, websites: Int = 0) { self.apps = apps; self.categories = categories; self.websites = websites }
    public var total: Int { apps + categories + websites }
}
