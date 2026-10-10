import SwiftUI

struct DashboardView: View {
    @Bindable var model: AppModel
    @State private var minutes = 25
    @State private var customMinutes = 90
    @State private var custom = false
    @State private var showSelection = false
    @State private var showFocus = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 7) { Eyebrow(text: "UNSCROLL"); Text(greeting).font(.title.weight(.bold)) }
                        Spacer()
                        Image(systemName: "sparkle").font(.title2).foregroundStyle(Palette.accent).accessibilityHidden(true)
                    }
                    Text("Your time. Your rules.").font(.subheadline).foregroundStyle(.secondary).padding(.top, -12)
                    if model.isPreview { PreviewBanner() }
                    if model.access != .approved {
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Screen Time access: \(model.access.rawValue)", systemImage: "hand.raised").font(.headline)
                                Text("Enable access to begin a focus session.").font(.subheadline).foregroundStyle(.secondary)
                                Button(model.isPreview ? "Enable demo permission" : "Request permission") { Task { await model.requestAuthorization() } }.disabled(model.isRequesting)
                            }
                        }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Eyebrow(text: "Today's focus")
                                    Text(minuteLabel(model.statistics.todayMinutes)).font(.system(.largeTitle, design: .rounded, weight: .semibold)).contentTransition(.numericText())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    Label("\(model.statistics.streak) day\(model.statistics.streak == 1 ? "" : "s")", systemImage: "flame").font(.subheadline.weight(.semibold)).foregroundStyle(Palette.accent)
                                    Text("current streak").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            ProgressView(value: min(1, Double(model.statistics.todayMinutes) / Double(model.goal))).tint(Palette.accent)
                                .accessibilityLabel("Daily focus goal").accessibilityValue("\(model.statistics.todayMinutes) of \(model.goal) minutes")
                            HStack { Text("\(model.statistics.todayMinutes) of \(model.goal) minutes"); Spacer(); Text("daily goal") }.font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let active = model.manager.active {
                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                Label(model.isPreview ? "Demo session running" : "Focus is in progress", systemImage: "circle.dotted.circle").font(.headline)
                                Text("Until \(active.end.formatted(date: .omitted, time: .shortened))").font(.subheadline).foregroundStyle(.secondary)
                                PrimaryButton(title: "Return to focus", icon: "arrow.up.right") { showFocus = true }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Eyebrow(text: "Make some space")
                            Text("How long will you focus?").font(.title3.weight(.semibold))
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 8) { durationButtons }
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) { durationButtons }
                            }
                            if custom { Stepper("\(customMinutes) minutes", value: $customMinutes, in: 15...720, step: 5).font(.subheadline) }
                            PrimaryButton(title: model.isPreview ? "Start demo focus" : "Start focus", icon: "play.fill") {
                                model.start(minutes: custom ? customMinutes : minutes)
                                if model.manager.active != nil { showFocus = true }
                            }.disabled(model.access != .approved || model.counts.total == 0)
                            if model.counts.total == 0 { Text("Choose a distraction below to get started.").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    Button { showSelection = true } label: {
                        Card {
                            HStack(spacing: 14) {
                                Image(systemName: "square.grid.2x2").font(.title3).foregroundStyle(Palette.accent).frame(width: 40, height: 40).background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 5) { Text("Your distractions").font(.subheadline.weight(.semibold)); Text(model.counts.summary).font(.caption).foregroundStyle(.secondary) }
                                Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                    if let last = model.manager.lastSession, !last.isPending {
                        Label(last.state == .completed ? "Session complete. A little space well spent." : last.state == .endedEarly ? "Session ended. Your time is yours." : "Session stopped safely. Review the error for details.", systemImage: last.state == .completed ? "checkmark.circle" : "circle").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text("A quieter phone. A fuller day.").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 8)
                }.padding(20)
            }
        }.toolbar(.hidden, for: .navigationBar)
            .onAppear { minutes = model.defaultMinutes; if ![25,45,60].contains(minutes) { custom = true; customMinutes = minutes } }
            .sheet(isPresented: $showSelection) { SelectionView(model: model) }
            .sheet(isPresented: $showFocus) { FocusView(model: model) }
    }
    @ViewBuilder private var durationButtons: some View {
        ForEach([25, 45, 60], id: \.self) { value in
            durationButton("\(value) min", selected: !custom && minutes == value) { minutes = value; custom = false }
        }
        durationButton("Custom", selected: custom) { custom = true }
    }
    private func durationButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15), action) } label: {
            Text(title).font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 13).padding(.horizontal, 9)
                .foregroundStyle(selected ? Color.primary : Color.secondary)
                .background(selected ? Palette.accent.opacity(0.22) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Palette.accent.opacity(0.65) : .clear))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) { case 0..<12: "Good morning."; case 12..<18: "Good afternoon."; default: "Good evening." }
    }
}
