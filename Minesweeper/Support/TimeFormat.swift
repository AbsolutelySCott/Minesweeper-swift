import Foundation

enum TimeFormat {
    /// `00:42` for under an hour, `1:02:07` beyond that.
    static func clock(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let remainingSeconds = clamped % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    /// The three-digit HUD treatment, e.g. `010`.
    static func counter(_ value: Int) -> String {
        String(format: "%03d", min(max(0, value), 999))
    }
}
