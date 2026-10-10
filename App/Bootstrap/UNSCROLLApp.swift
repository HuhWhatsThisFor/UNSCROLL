import SwiftUI
import Combine

@main struct UNSCROLLApp: App {
    @State private var model: AppModel?
    @State private var startupError: String?
    init() {
        do { _model = State(initialValue: try AppModel()) }
        catch {
            #if LIVE_MODE && !targetEnvironment(simulator)
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                LiveSchedulingService().clearOrphans(valid: [])
            }
            #endif
            _startupError = State(initialValue: error.localizedDescription)
        }
    }
    var body: some Scene {
        WindowGroup {
            if let model { RootView(model: model).preferredColorScheme(model.colorScheme) }
            else {
                ContentUnavailableView("Setup needs attention", systemImage: "exclamationmark.shield", description: Text(startupError ?? "Unable to open local storage."))
                    .padding().tint(Palette.accent)
            }
        }
    }
}

struct RootView: View {
    @Bindable var model: AppModel
    @Environment(\.scenePhase) private var phase
    @State private var tab = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        Group {
            if model.onboardingComplete {
                TabView(selection: $tab) {
                    NavigationStack { DashboardView(model: model) }.tabItem { Label("Home", systemImage: "house") }.tag(0)
                    NavigationStack { HistoryView(model: model) }.tabItem { Label("History", systemImage: "chart.bar.xaxis") }.tag(1)
                    NavigationStack { SettingsView(model: model) }.tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(2)
                }
            } else { OnboardingView(model: model) }
        }
        .tint(Palette.accent)
        .onChange(of: phase) { _, value in if value == .active { model.refresh() } }
        .onReceive(timer) { _ in if phase == .active, model.manager.active != nil { model.refresh() } }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in model.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemClockDidChange)) { _ in model.refresh() }
        .alert("Something needs attention", isPresented: Binding(get: { model.manager.errorMessage != nil }, set: { if !$0 { model.manager.dismissError() } })) {
            Button("OK") { model.manager.dismissError() }
        } message: { Text(model.manager.errorMessage ?? "") }
    }
}
