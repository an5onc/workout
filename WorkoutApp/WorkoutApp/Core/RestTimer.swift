import Foundation
import UserNotifications

/// Rest countdown stored as an end time, so it stays correct while the app is backgrounded or the phone is locked.
struct RestTimer: Hashable {
    private(set) var endDate: Date?
    private(set) var pausedRemaining: Int?

    var isRunning: Bool { endDate != nil }

    func remainingSeconds(at now: Date) -> Int {
        if let endDate {
            return max(0, Int(endDate.timeIntervalSince(now).rounded(.up)))
        }
        return pausedRemaining ?? 0
    }

    func isFinished(at now: Date) -> Bool {
        guard let endDate else { return false }
        return now >= endDate
    }

    mutating func start(seconds: Int, now: Date) {
        endDate = now.addingTimeInterval(TimeInterval(seconds))
        pausedRemaining = nil
    }

    mutating func pause(now: Date) {
        guard isRunning else { return }
        pausedRemaining = remainingSeconds(at: now)
        endDate = nil
    }

    /// Resumes a paused timer, or starts a fresh one when nothing is paused.
    mutating func resume(defaultSeconds: Int, now: Date) {
        let seconds = (pausedRemaining ?? 0) > 0 ? pausedRemaining! : defaultSeconds
        start(seconds: seconds, now: now)
    }

    mutating func reset() {
        endDate = nil
        pausedRemaining = nil
    }

    /// Parses plan rest text such as "90s", "60-75s", or "2 minutes". Untimed text ("Steady") falls back to 60s.
    static func seconds(fromRestText text: String) -> Int {
        guard let first = text.matches(of: /\d+/).first, let value = Int(first.output) else {
            return 60
        }
        let lowered = text.lowercased()
        if lowered.contains("min") {
            return value * 60
        }
        return value
    }
}

/// Schedules the "rest is over" local notification. Only one rest timer runs at a time.
enum RestTimerNotifier {
    static let identifier = "rest-timer"

    static func schedule(exerciseName: String, after seconds: Int) {
        guard seconds > 0 else { return }
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = "Rest is over"
            content.body = "Next set: \(exerciseName)"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
