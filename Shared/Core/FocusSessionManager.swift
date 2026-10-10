import Foundation
import Observation

@Observable @MainActor public final class FocusSessionManager {
    public private(set) var sessions: [FocusSession] = []
    public private(set) var lastSession: FocusSession?
    public private(set) var errorMessage: String?
    public let simulated: Bool
    @ObservationIgnored private let repository: any SessionRepository
    @ObservationIgnored private let authorization: any AuthorizationService
    @ObservationIgnored private let selection: any SelectionService
    @ObservationIgnored private let shields: any ShieldService
    @ObservationIgnored private let scheduler: any SchedulingService
    public var active: FocusSession? { sessions.first { $0.state == .active } }
    public init(repository: any SessionRepository, authorization: any AuthorizationService, selection: any SelectionService,
                shields: any ShieldService, scheduler: any SchedulingService, simulated: Bool) {
        self.repository = repository; self.authorization = authorization; self.selection = selection
        self.shields = shields; self.scheduler = scheduler; self.simulated = simulated
    }
    public func start(minutes: Int, now: Date = Date()) throws {
        try reconcile(now: now)
        guard authorization.status == .approved else { throw FocusError.permission }
        guard selection.counts.total > 0 else { throw FocusError.emptySelection }
        guard (15...720).contains(minutes) else { throw FocusError.invalidDuration }
        var session = FocusSession(start: now, end: now.addingTimeInterval(Double(minutes) * 60), simulated: simulated)
        // Durable intent precedes every system mutation; interrupted setup is cleared on recovery.
        try repository.transaction { records in
            guard !records.contains(where: { $0.isPending }) else { throw FocusError.overlapping }
            records.append(session)
        }
        do {
            try scheduler.start(session: session)
            guard authorization.status == .approved else { throw FocusError.permission }
            session.state = .active
            try repository.transaction { records in
                guard let index = records.firstIndex(where: { $0.id == session.id }), records[index].state == .preparing else {
                    throw FocusError.configuration("Session setup was interrupted. Try again.")
                }
                try shields.apply(session: session)
                records[index] = session
            }
            lastSession = session
            try reload()
        } catch {
            shields.clear(session: session); scheduler.stop(session: session)
            session.state = .failed; session.finishedAt = now; session.failure = error.localizedDescription
            try? repository.transaction { records in
                if let index = records.firstIndex(where: { $0.id == session.id }) { records[index] = session }
            }
            try? reload(); errorMessage = error.localizedDescription
            throw error
        }
    }
    public func stop(now: Date = Date()) throws {
        try reconcile(now: now)
        guard let session = active else { return }
        try finish(session, state: .endedEarly, now: now)
    }
    public func reconcile(now: Date = Date()) throws {
        let records: [FocusSession]
        do { records = try repository.read() }
        catch {
            // A known active session can still be unblocked when its journal becomes unreadable.
            for index in sessions.indices where sessions[index].isPending {
                let session = sessions[index]
                shields.clear(session: session); scheduler.stop(session: session)
                sessions[index].state = .failed; sessions[index].finishedAt = now
                sessions[index].failure = "Local session storage became unreadable. Restrictions were cleared."
            }
            lastSession = sessions.first
            throw error
        }
        for session in records where session.isPending {
            if session.state == .preparing {
                try finish(session, state: .failed, now: now, reason: "Session setup was interrupted.")
            } else if authorization.status != .approved {
                try finish(session, state: .failed, now: now, reason: "Screen Time permission was removed or became unavailable.")
            } else if now >= session.end {
                try finish(session, state: .completed, now: session.end)
            } else if !scheduler.isMonitoring(session: session) {
                try finish(session, state: .failed, now: now, reason: "The expiration monitor is missing. Restrictions were cleared for safety.")
            }
        }
        try reload()
    }
    private func finish(_ session: FocusSession, state: SessionState, now: Date, reason: String? = nil) throws {
        // Clear first so a storage failure can never strand an owned restriction.
        do {
            try repository.transaction { records in
                guard let index = records.firstIndex(where: { $0.id == session.id }), records[index].isPending else { return }
                shields.clear(session: session); scheduler.stop(session: session)
                records[index].state = state; records[index].finishedAt = now; records[index].failure = reason
            }
        } catch {
            shields.clear(session: session); scheduler.stop(session: session)
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index].state = .failed; sessions[index].finishedAt = now
                sessions[index].failure = "Restrictions were cleared, but the journal update failed."
                lastSession = sessions[index]
            }
            throw error
        }
        lastSession = try repository.read().first { $0.id == session.id }
        if let reason { errorMessage = reason }
        try reload()
    }
    public func clearHistory() throws {
        try repository.transaction { $0.removeAll { !$0.isPending } }
        lastSession = nil; try reload()
    }
    public func report(_ error: Error) { errorMessage = error.localizedDescription }
    public func dismissError() { errorMessage = nil }
    private func reload() throws {
        sessions = try repository.read().sorted { $0.start > $1.start }
        lastSession = sessions.first
    }
}
