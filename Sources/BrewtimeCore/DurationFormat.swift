import Foundation

public enum DurationFormat {
    /// Formats whole seconds as `45s`, `5m 03s`, `2h 05m` or `1d 3h`, keeping the two largest units.
    /// Negative input is clamped to `0s`.
    public static func string(fromSeconds seconds: Int) -> String {
        let seconds = max(seconds, 0)
        let days = seconds / 86_400
        let hours = seconds % 86_400 / 3_600
        let minutes = seconds % 3_600 / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h " + String(format: "%02dm", minutes) }
        if minutes > 0 { return "\(minutes)m " + String(format: "%02ds", seconds % 60) }
        return "\(seconds)s"
    }
}
