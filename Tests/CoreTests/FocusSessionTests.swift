import XCTest
#if SWIFT_PACKAGE
@testable import UnscrollCore
#else
@testable import UNSCROLL
#endif

final class FocusSessionTests: XCTestCase {
    @MainActor private func fixture() throws -> Fixture { try Fixture() }
    @MainActor func testStartPersistsActiveAndAppliesMockShield() async throws {
        let f = try fixture(); defer { f.remove() }
        try f.manager.start(minutes: 25, now: f.now)
        let active = try XCTUnwrap(f.manager.active)
        XCTAssertEqual(active.end, f.now.addingTimeInterval(1500))
        XCTAssertEqual(f.shields.owners, [active.storeName])
        XCTAssertTrue(f.scheduler.isMonitoring(session: active))
        XCTAssertEqual(try f.repository.read().first?.state, .active)
    }
    @MainActor func testEmptySelectionDoesNotMutateServices() async throws {
        let f = try fixture(); defer { f.remove() }; f.selection.counts = .init()
        XCTAssertThrowsError(try f.manager.start(minutes: 25, now: f.now))
        XCTAssertTrue(f.shields.owners.isEmpty); XCTAssertTrue(try f.repository.read().isEmpty)
    }
    @MainActor func testPermissionDenied() async throws {
        let f = try fixture(); defer { f.remove() }; f.auth.status = .denied
        XCTAssertThrowsError(try f.manager.start(minutes: 25, now: f.now)); XCTAssertNil(f.manager.active)
    }
    @MainActor func testInvalidDurationsRejected() async throws {
        let f = try fixture(); defer { f.remove() }
        for duration in [0, 14, 721] { XCTAssertThrowsError(try f.manager.start(minutes: duration, now: f.now)) }
        XCTAssertTrue(try f.repository.read().isEmpty)
    }
    @MainActor func testOverlappingFocusRejectedWithoutClearingFirst() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        let first = f.manager.active
        XCTAssertThrowsError(try f.manager.start(minutes: 45, now: f.now))
        XCTAssertEqual(f.manager.active?.id, first?.id); XCTAssertEqual(f.shields.owners.count, 1)
    }
    @MainActor func testExplicitStopClearsOnlyFocusAndDoesNotCountAsCompleted() async throws {
        let f = try fixture(); defer { f.remove() }
        // A future independent schedule owns a different named store.
        let shields = IndependentShieldService()
        let manager = f.makeManager(shields: shields)
        try manager.start(minutes: 25, now: f.now)
        try manager.stop(now: f.now.addingTimeInterval(10))
        XCTAssertFalse(shields.focus); XCTAssertTrue(shields.schedule)
        XCTAssertEqual(manager.sessions.first?.state, .endedEarly)
        XCTAssertEqual(FocusStatistics(sessions: manager.sessions, now: f.now).todayMinutes, 0)
    }
    @MainActor func testExpirationAtAbsoluteDeadline() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        try f.manager.reconcile(now: f.now.addingTimeInterval(1499)); XCTAssertNotNil(f.manager.active)
        try f.manager.reconcile(now: f.now.addingTimeInterval(1500))
        XCTAssertNil(f.manager.active); XCTAssertEqual(f.manager.lastSession?.state, .completed)
        XCTAssertTrue(f.shields.owners.isEmpty); XCTAssertTrue(f.scheduler.monitored.isEmpty)
    }
    @MainActor func testDelayedReconciliationUsesDeadlineForCompletion() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        try f.manager.reconcile(now: f.now.addingTimeInterval(9000))
        XCTAssertEqual(f.manager.sessions.first?.finishedAt, f.now.addingTimeInterval(1500))
    }
    @MainActor func testAuthorizationRevocationFailsAndUnblocks() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        f.auth.status = .revoked; try f.manager.reconcile(now: f.now.addingTimeInterval(10))
        XCTAssertEqual(f.manager.lastSession?.state, .failed); XCTAssertTrue(f.shields.owners.isEmpty)
    }
    @MainActor func testShieldFailureRollsBackMonitoring() async throws {
        let f = try fixture(); defer { f.remove() }; f.shields.shouldFail = true
        XCTAssertThrowsError(try f.manager.start(minutes: 25, now: f.now))
        XCTAssertTrue(f.scheduler.monitored.isEmpty); XCTAssertTrue(f.shields.owners.isEmpty)
        XCTAssertEqual(f.manager.sessions.first?.state, .failed)
    }
    @MainActor func testMonitorFailureNeverShields() async throws {
        let f = try fixture(); defer { f.remove() }; f.scheduler.shouldFail = true
        XCTAssertThrowsError(try f.manager.start(minutes: 25, now: f.now))
        XCTAssertTrue(f.shields.owners.isEmpty); XCTAssertEqual(f.manager.sessions.first?.state, .failed)
    }
    @MainActor func testInterruptedPreparationIsRecovered() async throws {
        let f = try fixture(); defer { f.remove() }
        let session = FocusSession(start: f.now, end: f.now.addingTimeInterval(1500), simulated: true)
        try f.repository.transaction { $0.append(session) }; try f.shields.apply(session: session)
        try f.manager.reconcile(now: f.now)
        XCTAssertEqual(f.manager.sessions.first?.state, .failed); XCTAssertTrue(f.shields.owners.isEmpty)
    }
    @MainActor func testRelaunchRestoresAndThenExpires() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        let relaunched = f.makeManager(shields: f.shields)
        try relaunched.reconcile(now: f.now.addingTimeInterval(500)); XCTAssertEqual(relaunched.active?.id, f.manager.active?.id)
        try relaunched.reconcile(now: f.now.addingTimeInterval(2000)); XCTAssertNil(relaunched.active)
    }
    @MainActor func testMissingMonitorFailsSafely() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        f.scheduler.stop(session: f.manager.active!)
        try f.manager.reconcile(now: f.now.addingTimeInterval(10))
        XCTAssertEqual(f.manager.sessions.first?.state, .failed); XCTAssertTrue(f.shields.owners.isEmpty)
    }
    @MainActor func testClearHistoryPreservesActiveSession() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        try f.manager.stop(now: f.now.addingTimeInterval(10))
        try f.manager.start(minutes: 25, now: f.now.addingTimeInterval(20))
        let activeID = f.manager.active?.id; try f.manager.clearHistory()
        XCTAssertEqual(f.manager.sessions.count, 1); XCTAssertEqual(f.manager.active?.id, activeID)
    }
    @MainActor func testExtensionCompletionIsShownAfterForegroundRefresh() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        let session = try XCTUnwrap(f.manager.active)
        try f.repository.transaction { records in
            MonitorRecovery.expire(id: session.id, now: session.end, records: &records) { f.shields.clear(session: $0) }
        }
        try f.manager.reconcile(now: session.end)
        XCTAssertNil(f.manager.active); XCTAssertEqual(f.manager.lastSession?.state, .completed)
    }
    @MainActor func testUnreadableJournalClearsKnownActiveRestriction() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        try Data("broken".utf8).write(to: f.directory.appendingPathComponent("sessions.json"))
        XCTAssertThrowsError(try f.manager.reconcile(now: f.now))
        XCTAssertTrue(f.shields.owners.isEmpty); XCTAssertTrue(f.scheduler.monitored.isEmpty)
        XCTAssertNil(f.manager.active); XCTAssertEqual(f.manager.lastSession?.state, .failed)
    }
    @MainActor func testStoppingAtDeadlineCountsCompletedOnce() async throws {
        let f = try fixture(); defer { f.remove() }; try f.manager.start(minutes: 25, now: f.now)
        try f.manager.stop(now: f.now.addingTimeInterval(1500))
        try f.manager.stop(now: f.now.addingTimeInterval(1501))
        XCTAssertEqual(f.manager.sessions.count, 1); XCTAssertEqual(f.manager.sessions.first?.state, .completed)
    }
    func testConcurrentRepositoryTransactionsDoNotLoseRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try FileSessionRepository(directory: directory)
        DispatchQueue.concurrentPerform(iterations: 25) { index in
            let start = Date(timeIntervalSince1970: Double(index) * 2000)
            // Separate descriptors acquire the same file lock even within one process.
            try! repository.transaction { $0.append(FocusSession(start: start, end: start.addingTimeInterval(1500), state: .completed, simulated: true)) }
        }
        XCTAssertEqual(try repository.read().count, 25)
    }
    func testStaleMonitorCallbackNeverClearsNewOwner() {
        let now = Date(timeIntervalSince1970: 1000)
        var old = FocusSession(start: now, end: now.addingTimeInterval(1500), state: .endedEarly, simulated: false)
        old.finishedAt = now.addingTimeInterval(100)
        let new = FocusSession(start: now.addingTimeInterval(101), end: now.addingTimeInterval(2800), state: .active, simulated: false)
        var records = [old, new]; var cleared = false
        XCTAssertFalse(MonitorRecovery.expire(id: old.id, now: now.addingTimeInterval(2000), records: &records) { _ in cleared = true })
        XCTAssertFalse(cleared); XCTAssertEqual(records[1].state, .active)
    }
    func testEarlyAndDuplicateMonitorCallbacksAreSafe() {
        let now = Date(timeIntervalSince1970: 1000)
        let session = FocusSession(start: now, end: now.addingTimeInterval(1500), state: .active, simulated: false)
        var records = [session]; var clearCount = 0
        XCTAssertFalse(MonitorRecovery.expire(id: session.id, now: now, records: &records) { _ in clearCount += 1 })
        XCTAssertTrue(MonitorRecovery.expire(id: session.id, now: session.end, records: &records) { _ in clearCount += 1 })
        XCTAssertFalse(MonitorRecovery.expire(id: session.id, now: session.end, records: &records) { _ in clearCount += 1 })
        XCTAssertEqual(clearCount, 1); XCTAssertEqual(records[0].state, .completed)
    }
    func testStatisticsExcludeEarlyAndFailedAndUseLocalDay() {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: -7 * 3600)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 12))!
        var records: [FocusSession] = []
        for offset in -2...0 {
            let day = calendar.date(byAdding: .day, value: offset, to: now)!
            records.append(FocusSession(start: day, end: day.addingTimeInterval(1500), state: .completed, simulated: true))
        }
        records.append(FocusSession(start: now, end: now.addingTimeInterval(3600), state: .endedEarly, simulated: true))
        let stats = FocusStatistics(sessions: records, calendar: calendar, now: now)
        XCTAssertEqual(stats.todayMinutes, 25); XCTAssertEqual(stats.completedCount, 3); XCTAssertEqual(stats.streak, 3); XCTAssertEqual(stats.week.count, 7)
    }
    func testProgressUsesDatesAndClamps() {
        let start = Date(timeIntervalSince1970: 1000)
        let session = FocusSession(start: start, end: start.addingTimeInterval(1500), simulated: true)
        XCTAssertEqual(session.progress(at: start.addingTimeInterval(750)), 0.5)
        XCTAssertEqual(session.progress(at: start.addingTimeInterval(-100)), 0)
        XCTAssertEqual(session.progress(at: start.addingTimeInterval(2000)), 1)
        XCTAssertEqual(session.remaining(at: start.addingTimeInterval(2000)), 0)
    }
    func testCorruptPersistenceIsNotSilentlyReplaced() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try FileSessionRepository(directory: directory)
        let file = directory.appendingPathComponent("sessions.json")
        try Data("broken".utf8).write(to: file)
        XCTAssertThrowsError(try repository.read()); XCTAssertThrowsError(try repository.transaction { $0.removeAll() })
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "broken")
    }
}

@MainActor private final class Fixture {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let now = Date(timeIntervalSince1970: 1_791_576_000)
    let repository: FileSessionRepository
    let auth = PreviewAuthorizationService()
    let selection = PreviewSelectionService()
    let shields = PreviewShieldService()
    let scheduler = PreviewSchedulingService()
    lazy var manager = makeManager(shields: shields)
    init() throws {
        repository = try FileSessionRepository(directory: directory)
        auth.status = .approved; selection.counts = .init(apps: 1)
    }
    func makeManager(shields: any ShieldService) -> FocusSessionManager {
        FocusSessionManager(repository: repository, authorization: auth, selection: selection, shields: shields, scheduler: scheduler, simulated: true)
    }
    func remove() { try? FileManager.default.removeItem(at: directory) }
}
@MainActor private final class IndependentShieldService: ShieldService {
    var focus = false
    var schedule = true
    func apply(session: FocusSession) throws { focus = true }
    func clear(session: FocusSession) { focus = false }
}
