import Foundation

public struct FocusStatistics {
    public let sessions: [FocusSession]
    public let calendar: Calendar
    public let now: Date
    public init(sessions: [FocusSession], calendar: Calendar = .current, now: Date = Date()) {
        self.sessions = sessions.filter { $0.state == .completed }; self.calendar = calendar; self.now = now
    }
    // Attribute completed duration to its completion day; never report device screen time.
    public func minutes(on day: Date) -> Int {
        Int(sessions.filter { calendar.isDate($0.finishedAt ?? $0.end, inSameDayAs: day) }.reduce(0) { $0 + $1.duration } / 60)
    }
    public var todayMinutes: Int { minutes(on: now) }
    public var completedCount: Int { sessions.count }
    public var streak: Int {
        var day = calendar.startOfDay(for: now)
        if minutes(on: day) == 0 { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while minutes(on: day) > 0 {
            count += 1; day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }
    public var week: [Date] { (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - 6, to: calendar.startOfDay(for: now)) } }
}
