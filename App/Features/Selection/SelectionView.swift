import SwiftUI
import FamilyControls

struct SelectionView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft = FamilyActivitySelection()
    @State private var demo = Set<String>()
    private let demoApps = ["Social feed", "Short videos", "Games", "News"]
    var body: some View {
        NavigationStack {
            Group {
                if model.manager.active != nil {
                    ContentUnavailableView("Focus is in progress", systemImage: "lock.shield", description: Text("End your current session before changing its selection."))
                } else if model.isPreview {
                    List {
                        Section { PreviewBanner().listRowBackground(Color.clear) }
                        Section("Illustrative demo choices") {
                            ForEach(demoApps, id: \.self) { name in
                                Button {
                                    if demo.contains(name) { demo.remove(name) } else { demo.insert(name) }
                                } label: {
                                    HStack { Label(name, systemImage: "app"); Spacer(); if demo.contains(name) { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.accent) } }.foregroundStyle(.primary)
                                }.accessibilityValue(demo.contains(name) ? "Selected" : "Not selected")
                            }
                        }
                        Section { Text("These are mock choices, not installed applications. The real Apple picker is used only in a provisioned live build.").font(.footnote).foregroundStyle(.secondary) }
                    }
                } else if model.access == .approved { FamilyActivityPicker(selection: $draft) }
                else {
                    ContentUnavailableView {
                        Label("Screen Time access needed", systemImage: "hand.raised")
                    } description: { Text("Authorize access to open Apple’s private app picker.") } actions: {
                        Button("Request access") { Task { await model.requestAuthorization() } }.disabled(model.isRequesting)
                    }
                }
            }
            .navigationTitle(model.isPreview ? "Demo distractions" : "Distractions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.isPreview { model.demoChoices = demo } else { model.saveSelection(draft) }
                        dismiss()
                    }.disabled(model.manager.active != nil || (!model.isPreview && model.access != .approved))
                }
            }
            .onAppear { draft = (model.selection as? LiveSelectionService)?.selection ?? FamilyActivitySelection(); demo = model.demoChoices }
        }
    }
}
