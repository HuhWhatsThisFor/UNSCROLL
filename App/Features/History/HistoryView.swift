import SwiftUI

struct HistoryView: View {
    @Bindable var model: AppModel
    var body: some View {
        ZStack {
            PageBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Time well spent.").font(.title.weight(.bold))
                    Text("Your UNSCROLL sessions, saved on this iPhone.").font(.subheadline).foregroundStyle(.secondary)
                    if model.isPreview { PreviewBanner() }
                    Card {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack { Eyebrow(text: "Last 7 days"); Spacer(); Text("\(model.statistics.completedCount) completed").font(.caption).foregroundStyle(.secondary) }
                            HStack(alignment: .bottom, spacing: 10) {
                                ForEach(model.statistics.week, id: \.self) { day in
                                    let value = model.statistics.minutes(on: day)
                                    VStack(spacing: 8) {
                                        Text("\(value)").font(.caption2).foregroundStyle(.secondary)
                                        RoundedRectangle(cornerRadius: 5).fill(Calendar.current.isDateInToday(day) ? Palette.accent : Palette.accent.opacity(0.40)).frame(height: max(4, 90 * Double(value) / Double(max(model.goal, model.statistics.week.map { model.statistics.minutes(on: $0) }.max() ?? 1))))
                                        Text(day.formatted(.dateTime.weekday(.narrow))).font(.caption).foregroundStyle(.secondary)
                                    }.frame(maxWidth: .infinity).accessibilityElement(children: .ignore).accessibilityLabel(day.formatted(date: .abbreviated, time: .omitted)).accessibilityValue("\(value) completed focus minutes")
                                }
                            }.frame(height: 135, alignment: .bottom)
                        }
                    }
                    Eyebrow(text: "Session journal")
                    if model.manager.sessions.isEmpty {
                        ContentUnavailableView("Your first page is blank", systemImage: "leaf", description: Text("Complete a focus session and it will appear here."))
                    } else {
                        ForEach(model.manager.sessions) { session in
                            Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: session.state == .completed ? "checkmark.circle" : session.state == .active ? "circle.dotted" : "minus.circle").foregroundStyle(Palette.accent)
                                        Text(stateLabel(session.state)).font(.subheadline.weight(.semibold)); Spacer()
                                        Text(durationLabel(session)).font(.subheadline.monospacedDigit())
                                    }
                                    Text(session.start.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                                    if session.state == .endedEarly || session.state == .failed {
                                        Text("Planned focus: \(minuteLabel(Int(session.duration / 60)))").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    if session.simulated { Text("Preview session · simulated").font(.caption2).foregroundStyle(.secondary) }
                                    if let failure = session.failure { Text(failure).font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }
                    Text("Only completed sessions count toward focus time and streaks. Duration is attributed to the day the session completed; these are not device usage statistics.").font(.footnote).foregroundStyle(.secondary).lineSpacing(3)
                }.padding(20)
            }
        }.navigationTitle("History").navigationBarTitleDisplayMode(.inline)
    }
    private func durationLabel(_ session: FocusSession) -> String {
        if session.state == .endedEarly || session.state == .failed {
            let elapsed = max(0, min(session.duration, (session.finishedAt ?? session.start).timeIntervalSince(session.start)))
            return elapsed < 60 ? "Under 1m" : minuteLabel(Int(elapsed / 60))
        }
        return minuteLabel(Int(session.duration / 60))
    }
    private func stateLabel(_ state: SessionState) -> String {
        switch state { case .preparing: "Preparing"; case .active: "In progress"; case .completed: "Completed"; case .endedEarly: "Ended early"; case .failed: "Stopped safely" }
    }
}
