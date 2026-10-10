import SwiftUI

struct OnboardingView: View {
    @Bindable var model: AppModel
    @State private var step = 0
    @State private var showSelection = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let titles = ["Make room for\nwhat matters.", "A little distance.\nA lot more presence.", "Permission,\non your terms.", "Choose your\ndistractions."]
    private let descriptions = ["Your time. Your rules.\nA calmer relationship with your phone starts here.", "Pick the apps that pull you away. UNSCROLL creates space to focus, with everything kept on your iPhone.", "Apple’s Screen Time permission lets UNSCROLL apply system shields. You can stop a session or revoke access whenever you choose.", "Select apps, categories, and websites with Apple’s private picker. Your choices stay on this device."]
    var body: some View {
        NavigationStack {
            ZStack {
                PageBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack { Image(systemName: "circle.lefthalf.filled").foregroundStyle(Palette.accent); Text("UNSCROLL").font(.headline).tracking(4) }.padding(.top, 20)
                        if model.isPreview { PreviewBanner() }
                        ZStack {
                            Circle().fill(Palette.accent.opacity(0.06)).frame(width: 200, height: 200)
                            Circle().stroke(Palette.accent.opacity(0.20), lineWidth: 1).frame(width: 154, height: 154)
                            Image(systemName: ["sparkle", "leaf", "hand.raised", "app.badge.checkmark"][step]).font(.system(size: 58, weight: .ultraLight)).foregroundStyle(Palette.accent)
                        }.frame(maxWidth: .infinity).padding(.vertical, 12).accessibilityHidden(true)
                        Text(titles[step]).font(.system(.largeTitle, design: .rounded, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                        Text(descriptions[step]).font(.body).foregroundStyle(.secondary).lineSpacing(5)
                        if step == 1 {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("No accounts. No subscriptions.", systemImage: "person.crop.circle.badge.checkmark")
                                Label("No analytics or advertisements.", systemImage: "eye.slash")
                                Label("Free, open source, and local.", systemImage: "lock.shield")
                            }.font(.subheadline)
                        }
                        if step == 2 {
                            Label(accessDescription, systemImage: model.access == .approved ? "checkmark.shield" : "hand.raised")
                                .font(.subheadline).foregroundStyle(.secondary)
                            if model.access != .approved {
                                PrimaryButton(title: model.isRequesting ? "Requesting access…" : model.isPreview ? "Simulate permission" : "Allow Screen Time", icon: "lock.open") { Task { await model.requestAuthorization() } }.disabled(model.isRequesting)
                            }
                        }
                        if step == 3 {
                            Card {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label(model.counts.total == 0 ? "No distractions selected" : model.counts.summary, systemImage: "square.grid.2x2")
                                    Button(model.isPreview ? "Choose demo apps" : "Choose apps & websites") { showSelection = true }
                                }
                            }
                        }
                        HStack(spacing: 6) { ForEach(0..<4) { index in Capsule().fill(index == step ? Palette.accent : .secondary.opacity(0.25)).frame(width: index == step ? 24 : 7, height: 7) } }.accessibilityLabel("Step \(step + 1) of 4")
                        PrimaryButton(title: step == 3 ? "Find your focus" : "Continue") {
                            if step == 3 { model.onboardingComplete = true }
                            else { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { step += 1 } }
                        }
                        if step == 2, model.access != .approved {
                            Text("You can continue exploring and enable permission later in Settings.").font(.caption).foregroundStyle(.secondary)
                        }
                        if step > 0 { Button("Back") { step -= 1 }.font(.subheadline) }
                    }.padding(24)
                }
            }.toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showSelection) { SelectionView(model: model) }
        }
    }
    private var accessDescription: String {
        switch model.access {
        case .approved: model.isPreview ? "Demo permission enabled" : "Screen Time access enabled"
        case .restricted: "Screen Time is restricted. UNSCROLL cannot override these controls."
        case .unavailable: "Screen Time authorization is unavailable on this device or account."
        case .denied: "Permission was denied. You can try again or continue exploring."
        case .revoked: "Permission was revoked. You can authorize again when ready."
        case .notDetermined: "Only voluntary individual authorization is requested."
        }
    }
}
