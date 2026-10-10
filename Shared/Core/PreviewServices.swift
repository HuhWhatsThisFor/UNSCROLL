import Foundation
import Observation

@Observable @MainActor public final class PreviewAuthorizationService: AuthorizationService {
    public var status: AccessState = .notDetermined
    public init() {}
    public func request() async throws { status = .approved }
}
@Observable @MainActor public final class PreviewSelectionService: SelectionService {
    public var counts = SelectionCounts()
    public init() {}
}
@MainActor public final class PreviewShieldService: ShieldService {
    public private(set) var owners = Set<String>()
    public var shouldFail = false
    public init() {}
    public func apply(session: FocusSession) throws {
        if shouldFail { throw FocusError.shielding }
        owners.insert(session.storeName)
    }
    public func clear(session: FocusSession) { owners.remove(session.storeName) }
}
@MainActor public final class PreviewSchedulingService: SchedulingService {
    public private(set) var monitored = Set<UUID>()
    public var shouldFail = false
    public init() {}
    public func start(session: FocusSession) throws {
        if shouldFail { throw FocusError.configuration("Expiration monitor could not start.") }
        monitored.insert(session.id)
    }
    public func stop(session: FocusSession) { monitored.remove(session.id) }
    public func isMonitoring(session: FocusSession) -> Bool { monitored.contains(session.id) }
    public func restore(_ sessions: [FocusSession]) { monitored = Set(sessions.filter { $0.state == .active }.map(\.id)) }
}
