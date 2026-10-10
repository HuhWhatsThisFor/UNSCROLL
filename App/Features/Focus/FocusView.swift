import SwiftUI

struct FocusView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmStop = false
    @State private var displayedSession: FocusSession?
    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        if model.isPreview { PreviewBanner() }
                        Eyebrow(text: model.manager.active == nil ? "Room to breathe" : "One thing at a time").padding(.top, 16)
                        Text(model.manager.active == nil ? completionTitle : "You’re here. Stay here.").font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let session = model.manager.active ?? displayedSession
                            let remaining = model.manager.active == nil ? 0 : session?.remaining(at: context.date) ?? 0
                            ZStack {
                                Circle().stroke(Palette.accent.opacity(0.12), lineWidth: 9)
                                Circle().trim(from: 0, to: session?.progress(at: context.date) ?? 1).stroke(Palette.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
                                VStack(spacing: 8) {
                                    Text(model.manager.active == nil ? "checkmark" : "leaf").hidden().overlay(Image(systemName: model.manager.active == nil ? "checkmark" : "leaf").foregroundStyle(Palette.accent))
                                    Text(countdown(remaining)).font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                                    Text(model.manager.active == nil ? "session finished" : "remaining").font(.caption).foregroundStyle(.secondary)
                                }.padding(24)
                            }.frame(maxWidth: 280).aspectRatio(1, contentMode: .fit).padding(.horizontal, 24)
                                .accessibilityElement(children: .ignore).accessibilityLabel("Focus timer").accessibilityValue(model.manager.active == nil ? "Session finished" : "\(Int(ceil(remaining / 60))) minutes remaining")
                        }
                        if let session = model.manager.active {
                            VStack(spacing: 10) {
                                Label(model.isPreview ? "Simulated restrictions · \(model.counts.total) demo \(model.counts.total == 1 ? "choice" : "choices")" : "Shield configured · \(model.counts.total) selections", systemImage: model.isPreview ? "viewfinder" : "shield.lefthalf.filled").font(.subheadline)
                                Text("Finishes at \(session.end.formatted(date: .omitted, time: .shortened))").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Card {
                                Text(model.isPreview ? "Explore the timer and session history. This build cannot restrict access to apps." : "Apple manages the shield. Background expiration may be delayed by iOS; opening UNSCROLL reconciles the deadline and clears expired restrictions.").font(.footnote).foregroundStyle(.secondary).lineSpacing(3)
                            }
                            Button("End session early", role: .destructive) { confirmStop = true }.padding(.vertical, 12)
                        } else {
                            Text(completionMessage).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            PrimaryButton(title: "Back to your day", icon: "checkmark") { dismiss() }
                        }
                    }.padding(24)
                }
            }.navigationTitle("Focus").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
                .confirmationDialog("End this session?", isPresented: $confirmStop, titleVisibility: .visible) {
                    Button("End session", role: .destructive) { model.stop() }
                    Button("Keep focusing", role: .cancel) {}
                } message: { Text("UNSCROLL will remove this session’s restrictions. Early sessions do not count toward completed focus time.") }
                .onAppear { displayedSession = model.manager.active ?? model.manager.lastSession }
        }
    }
    private var completionTitle: String {
        switch model.manager.lastSession?.state { case .completed: "Space, well spent."; case .endedEarly: "Your time is yours."; default: "Session stopped." }
    }
    private var completionMessage: String {
        switch model.manager.lastSession?.state {
        case .completed: model.isPreview ? "Your completed demo session is saved locally." : "Your completed session is saved. UNSCROLL’s focus restrictions have been cleared."
        case .endedEarly: "This session ended early and won’t count toward your goal."
        default: model.manager.lastSession?.failure ?? "There is no active focus session."
        }
    }
    private func countdown(_ remaining: Double) -> String {
        let seconds = Int(ceil(remaining)); return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
