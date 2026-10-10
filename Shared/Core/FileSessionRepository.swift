import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// Both processes use the same advisory lock. Atomic rename protects against termination mid-write.
public struct FileSessionRepository: SessionRepository {
    public let directory: URL
    public init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    public func read() throws -> [FocusSession] { try locked { try load() } }
    public func transaction(_ change: (inout [FocusSession]) throws -> Void) throws {
        try locked {
            var sessions = try load()
            try change(&sessions)
            try JSONEncoder().encode(sessions).write(to: directory.appendingPathComponent("sessions.json"), options: .atomic)
        }
    }
    private func load() throws -> [FocusSession] {
        let file = directory.appendingPathComponent("sessions.json")
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return try JSONDecoder().decode([FocusSession].self, from: Data(contentsOf: file))
    }
    private func locked<T>(_ body: () throws -> T) throws -> T {
        let descriptor = open(directory.appendingPathComponent("sessions.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw FocusError.persistence("Unable to open lock") }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw FocusError.persistence("Unable to lock storage") }
        defer { flock(descriptor, LOCK_UN) }
        return try body()
    }
}
