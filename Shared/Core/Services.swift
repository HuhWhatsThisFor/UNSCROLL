import Foundation

@MainActor public protocol AuthorizationService: AnyObject {
    var status: AccessState { get }
    func request() async throws
}
@MainActor public protocol SelectionService: AnyObject { var counts: SelectionCounts { get } }
@MainActor public protocol ShieldService: AnyObject {
    func apply(session: FocusSession) throws
    func clear(session: FocusSession)
}
@MainActor public protocol SchedulingService: AnyObject {
    func start(session: FocusSession) throws
    func stop(session: FocusSession)
    func isMonitoring(session: FocusSession) -> Bool
}
public protocol SessionRepository: Sendable {
    func read() throws -> [FocusSession]
    func transaction(_ change: (inout [FocusSession]) throws -> Void) throws
}
