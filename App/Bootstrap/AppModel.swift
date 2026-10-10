import Foundation
import SwiftUI
import Observation
import FamilyControls
import Combine

@Observable @MainActor final class AppModel {
    let manager: FocusSessionManager
    let authorization: any AuthorizationService
    let selection: any SelectionService
    let defaults: UserDefaults
    let isPreview: Bool
    var access: AccessState = .notDetermined
    var counts = SelectionCounts()
    var isRequesting = false
    var onboardingComplete: Bool { didSet { defaults.set(onboardingComplete, forKey: "onboardingComplete") } }
    var appearance: String { didSet { defaults.set(appearance, forKey: "appearance") } }
    var defaultMinutes: Int { didSet { defaults.set(defaultMinutes, forKey: "defaultMinutes") } }
    var goal: Int { didSet { defaults.set(goal, forKey: "goal") } }
    var demoChoices: Set<String> { didSet {
        defaults.set(Array(demoChoices), forKey: "demoChoices")
        (selection as? PreviewSelectionService)?.counts = .init(apps: demoChoices.count)
        counts = selection.counts
    } }
    @ObservationIgnored private let scheduler: any SchedulingService
    @ObservationIgnored private var authorizationSubscription: AnyCancellable?
    var colorScheme: ColorScheme? { appearance == "dark" ? .dark : appearance == "light" ? .light : nil }
    var statistics: FocusStatistics { FocusStatistics(sessions: manager.sessions) }
    init() throws {
        #if LIVE_MODE && !targetEnvironment(simulator)
        let preview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        let preview = Self.previewRequired()
        #endif
        isPreview = preview
        let directory: URL

        let shields: any ShieldService
        let repository: FileSessionRepository
        if preview {
            #if DEBUG
            let testNamespace = ProcessInfo.processInfo.environment["UNSCROLL_TEST_NAMESPACE"]
            #else
            let testNamespace: String? = nil
            #endif
            defaults = UserDefaults(suiteName: "org.unscroll.preview" + (testNamespace.map { "." + $0 } ?? ""))!
            #if DEBUG
            if testNamespace != nil, let style = ProcessInfo.processInfo.environment["UNSCROLL_TEST_APPEARANCE"],
               ["dark", "light", "system"].contains(style) { defaults.set(style, forKey: "appearance") }
            #endif
            directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("PreviewSessions" + (testNamespace.map { "-" + $0 } ?? ""))
            repository = try FileSessionRepository(directory: directory)
            let auth = PreviewAuthorizationService()
            if defaults.bool(forKey: "previewAuthorized") { auth.status = .approved }
            authorization = auth
            let selections = PreviewSelectionService()
            selections.counts = .init(apps: (defaults.stringArray(forKey: "demoChoices") ?? []).count)
            selection = selections
            let mockScheduler = PreviewSchedulingService()
            mockScheduler.restore(try repository.read())
            scheduler = mockScheduler
            let mockShields = PreviewShieldService()
            for session in try repository.read() where session.state == .active { try mockShields.apply(session: session) }
            shields = mockShields
        } else {
            guard let group = Bundle.main.object(forInfoDictionaryKey: "UnscrollAppGroup") as? String,
                  !group.isEmpty, !group.contains("$("),
                  let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group),
                  let preferences = UserDefaults(suiteName: group) else {
                throw FocusError.configuration("Live mode needs a provisioned App Group shared by the app and monitor. Follow the signing checklist in README.md, or use the UNSCROLL Preview scheme.")
            }
            defaults = preferences; directory = container.appendingPathComponent("FocusSessions")
            repository = try FileSessionRepository(directory: directory)
            let auth = LiveAuthorizationService(); authorization = auth
            let selections = try LiveSelectionService(defaults: preferences); selection = selections
            scheduler = LiveSchedulingService(); shields = LiveShieldService(selection: selections, authorization: auth)
        }
        manager = FocusSessionManager(repository: repository, authorization: authorization, selection: selection, shields: shields, scheduler: scheduler, simulated: preview)
        onboardingComplete = defaults.bool(forKey: "onboardingComplete")
        appearance = defaults.string(forKey: "appearance") ?? "system"
        defaultMinutes = max(15, min(720, defaults.object(forKey: "defaultMinutes") as? Int ?? 25))
        goal = max(15, min(720, defaults.object(forKey: "goal") as? Int ?? 60))
        demoChoices = Set(defaults.stringArray(forKey: "demoChoices") ?? [])
        refresh()
        if let live = scheduler as? LiveSchedulingService {
            do { live.clearOrphans(valid: Set(try repository.read().filter(\.isPending).map(\.id))) }
            catch { live.clearOrphans(valid: []); manager.report(error) }
        }
        if !preview {
            authorizationSubscription = AuthorizationCenter.shared.$authorizationStatus.dropFirst().sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refresh() }
            }
        }
    }
    private static func previewRequired() -> Bool { true }
    func refresh() {
        access = authorization.status; counts = selection.counts
        do { try manager.reconcile() }
        catch { (scheduler as? LiveSchedulingService)?.clearOrphans(valid: []); manager.report(error) }
    }
    func requestAuthorization() async {
        guard !isRequesting else { return }
        isRequesting = true; defer { isRequesting = false; refresh() }
        do {
            try await authorization.request()
            if isPreview { defaults.set(true, forKey: "previewAuthorized") }
        } catch { manager.report(error) }
    }
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
    func start(minutes: Int) { do { try manager.start(minutes: minutes) } catch { manager.report(error) } }
    func stop() { do { try manager.stop() } catch { manager.report(error) } }
    func clearHistory() { do { try manager.clearHistory() } catch { manager.report(error) } }
    func saveSelection(_ selection: FamilyActivitySelection) {
        do { try (self.selection as? LiveSelectionService)?.save(selection); counts = self.selection.counts }
        catch { manager.report(error) }
    }
}
