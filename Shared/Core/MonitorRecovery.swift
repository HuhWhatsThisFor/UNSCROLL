import Foundation

public enum MonitorRecovery {
    /// Must be called inside a repository transaction, including the restriction mutation.
    @discardableResult public static func expire(id: UUID, now: Date, records: inout [FocusSession], clear: (FocusSession) -> Void) -> Bool {
        guard let index = records.firstIndex(where: { $0.id == id }), records[index].isPending,
              now >= records[index].end else { return false }
        clear(records[index])
        records[index].state = records[index].state == .active ? .completed : .failed
        records[index].finishedAt = records[index].end
        if records[index].state == .failed { records[index].failure = "Session setup did not finish." }
        return true
    }
}
