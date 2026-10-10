import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

@MainActor final class LiveAuthorizationService: AuthorizationService {
    private var wasApproved = false
    private var requestFailure: AccessState?
    var status: AccessState {
        let raw = AuthorizationCenter.shared.authorizationStatus
        if raw == .approved { wasApproved = true; return .approved }
        if #available(iOS 26.4, *), raw == .approvedWithDataAccess { wasApproved = true; return .approved }
        if let requestFailure { return requestFailure }
        if wasApproved { return .revoked }
        return raw == .denied ? .denied : .notDetermined
    }
    func request() async throws {
        requestFailure = nil
        do { try await AuthorizationCenter.shared.requestAuthorization(for: .individual) }
        catch {
            if let failure = error as? FamilyControlsError {
                switch failure {
                case .restricted: requestFailure = .restricted
                case .unavailable, .invalidAccountType, .authenticationMethodUnavailable: requestFailure = .unavailable
                default: break
                }
            }
            throw error
        }
    }
}

@MainActor final class LiveSelectionService: SelectionService {
    private let defaults: UserDefaults
    private(set) var selection: FamilyActivitySelection
    var counts: SelectionCounts { .init(apps: selection.applicationTokens.count, categories: selection.categoryTokens.count, websites: selection.webDomainTokens.count) }
    init(defaults: UserDefaults) throws {
        self.defaults = defaults
        if let data = defaults.data(forKey: "familySelection") { selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data) }
        else { selection = FamilyActivitySelection() }
    }
    func save(_ value: FamilyActivitySelection) throws {
        let data = try JSONEncoder().encode(value)
        defaults.set(data, forKey: "familySelection"); selection = value
    }
}

@MainActor final class LiveShieldService: ShieldService {
    private let selection: LiveSelectionService
    private let authorization: LiveAuthorizationService
    init(selection: LiveSelectionService, authorization: LiveAuthorizationService) { self.selection = selection; self.authorization = authorization }
    func apply(session: FocusSession) throws {
        guard authorization.status == .approved else { throw FocusError.permission }
        guard selection.counts.total > 0 else { throw FocusError.emptySelection }
        let value = selection.selection
        let store = ManagedSettingsStore(named: .init(session.storeName))
        store.shield.applications = value.applicationTokens.isEmpty ? nil : value.applicationTokens
        store.shield.applicationCategories = value.categoryTokens.isEmpty ? nil : .specific(value.categoryTokens)
        store.shield.webDomains = value.webDomainTokens.isEmpty ? nil : value.webDomainTokens
        store.shield.webDomainCategories = value.categoryTokens.isEmpty ? nil : .specific(value.categoryTokens)
        // These setters are synchronous and nonthrowing. Read back configuration; Apple offers no enforcement receipt.
        guard store.shield.applications == (value.applicationTokens.isEmpty ? nil : value.applicationTokens),
              store.shield.webDomains == (value.webDomainTokens.isEmpty ? nil : value.webDomainTokens),
              store.shield.applicationCategories == (value.categoryTokens.isEmpty ? nil : .specific(value.categoryTokens)),
              store.shield.webDomainCategories == (value.categoryTokens.isEmpty ? nil : .specific(value.categoryTokens)) else { throw FocusError.shielding }
    }
    func clear(session: FocusSession) { ManagedSettingsStore(named: .init(session.storeName)).clearAllSettings() }
}

@MainActor final class LiveSchedulingService: SchedulingService {
    private let center = DeviceActivityCenter()
    static let prefix = "unscroll.session."
    static func name(_ session: FocusSession) -> DeviceActivityName { .init(prefix + session.id.uuidString) }
    func start(session: FocusSession) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let fields: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        var start = calendar.dateComponents(fields, from: session.start)
        var end = calendar.dateComponents(fields, from: session.end)
        start.calendar = calendar; end.calendar = calendar; start.timeZone = calendar.timeZone; end.timeZone = calendar.timeZone
        try center.startMonitoring(Self.name(session), during: DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: false))
    }
    func stop(session: FocusSession) { center.stopMonitoring([Self.name(session)]) }
    func isMonitoring(session: FocusSession) -> Bool { center.activities.contains(Self.name(session)) }
    // Emergency recovery is limited to UNSCROLL's focus store and monitor prefix.
    func clearOrphans(valid: Set<UUID>) {
        for name in center.activities where name.rawValue.hasPrefix(Self.prefix) {
            let suffix = String(name.rawValue.dropFirst(Self.prefix.count))
            if let id = UUID(uuidString: suffix), !valid.contains(id) { center.stopMonitoring([name]) }
        }
        if valid.isEmpty { ManagedSettingsStore(named: .init("unscroll.focus")).clearAllSettings() }
    }
}
