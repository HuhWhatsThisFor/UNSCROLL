import DeviceActivity
import ManagedSettings
import Foundation

final class FocusMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) { reconcile(activity) }
    override func intervalDidEnd(for activity: DeviceActivityName) { reconcile(activity) }
    private func reconcile(_ activity: DeviceActivityName) {
        let prefix = "unscroll.session."
        guard activity.rawValue.hasPrefix(prefix),
              let id = UUID(uuidString: String(activity.rawValue.dropFirst(prefix.count))),
              let group = Bundle.main.object(forInfoDictionaryKey: "UnscrollAppGroup") as? String,
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { return }
        do {
            let repository = try FileSessionRepository(directory: container.appendingPathComponent("FocusSessions"))
            var expired = false
            try repository.transaction { records in
                expired = MonitorRecovery.expire(id: id, now: Date(), records: &records) { session in
                    ManagedSettingsStore(named: .init(session.storeName)).clearAllSettings()
                }
            }
            if expired { DeviceActivityCenter().stopMonitoring([activity]) }
        } catch {
            // Preserve corrupted data for inspection. Foreground recovery clears UNSCROLL-owned settings.
            NSLog("UNSCROLL monitor: local session reconciliation failed (%@)", error.localizedDescription)
        }
    }
}
