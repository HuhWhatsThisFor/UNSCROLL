import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var showSelection = false
    @State private var confirmClear = false
    var body: some View {
        Form {
            if model.isPreview { Section { PreviewBanner() } }
            Section("Make it yours") {
                Picker("Appearance", selection: $model.appearance) { Text("System").tag("system"); Text("Light").tag("light"); Text("Dark").tag("dark") }
                Stepper("Default focus: \(model.defaultMinutes) min", value: $model.defaultMinutes, in: 15...720, step: 5)
                Stepper("Daily goal: \(model.goal) min", value: $model.goal, in: 15...720, step: 15)
            }
            Section("Distractions") {
                Button { showSelection = true } label: { HStack { Text("Change selection"); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) } }
                    .disabled(model.manager.active != nil)
                Text(model.counts.summary).font(.caption).foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("Authorization", value: model.isPreview ? "Demo: \(model.access.rawValue)" : model.access.rawValue.capitalized)
                if model.access != .approved {
                    Button(model.isPreview ? "Simulate authorization" : "Request Screen Time access") { Task { await model.requestAuthorization() } }.disabled(model.isRequesting)
                }
                Button("Open iPhone Settings") {
                    model.openSystemSettings()
                }
            } header: { Text("Screen Time") } footer: {
                Text("Manage individual authorization in iPhone Settings → Screen Time → Apps with Screen Time Access. UNSCROLL cannot override restricted permissions or parental controls.")
            }
            Section("Your data") {
                NavigationLink("Privacy") { InformationView(title: "Privacy", icon: "lock.shield", paragraphs: ["Your focus belongs to you.", "UNSCROLL has no account system, analytics SDK, advertisements, server, or network requests. App selections use Apple’s opaque tokens; UNSCROLL does not decode or identify your installed apps.", "Selection and settings are stored in local preferences. Session records are stored in an atomic local file, shared only with the monitor through the configured App Group in live builds.", "Your iPhone’s system backup may include local app data. Clear session history here to remove completed, early-ended, and failed session records. Remove the app to delete its local data.", "Statistics describe UNSCROLL focus sessions. They do not measure total device screen time or app usage."]) }
                Button("Clear session history", role: .destructive) { confirmClear = true }
            }
            Section {
                NavigationLink("About UNSCROLL") { InformationView(title: "UNSCROLL", icon: "circle.lefthalf.filled", paragraphs: ["Your time. Your rules.", "A free, open-source focus app for voluntary self-management. No subscriptions, upgrades, or paid core services.", "Built with SwiftUI and Apple’s Screen Time frameworks. iOS 17 or later. Source code is provided under the MIT license in this project.", "Live blocking requires a correctly provisioned build on a physical iPhone. Apple’s callbacks can be delayed; reopening UNSCROLL reconciles expired sessions. You can always end a session early."]) }
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Integration", value: model.isPreview ? "Preview" : "Live")
            }
        }.navigationTitle("Settings")
            .sheet(isPresented: $showSelection) { SelectionView(model: model) }
            .confirmationDialog("Clear local session history?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) { model.clearHistory() }; Button("Cancel", role: .cancel) {}
            } message: { Text("This deletes finished session records. An active focus session will continue.") }
    }
}
struct InformationView: View {
    let title: String
    let icon: String
    let paragraphs: [String]
    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: icon).font(.largeTitle).foregroundStyle(Palette.accent).accessibilityHidden(true)
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, text in
                        Text(text).font(index == 0 ? .title2.weight(.semibold) : .body).foregroundStyle(index == 0 ? .primary : .secondary).lineSpacing(4)
                    }
                }.padding(24)
            }
        }.navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}
#Preview { if let model = try? AppModel() { RootView(model: model).preferredColorScheme(.dark) } }
