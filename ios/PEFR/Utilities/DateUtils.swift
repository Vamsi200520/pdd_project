import Foundation

struct DateUtils {
    static func parseRobustDate(_ dateString: String) -> Date? {
        // Try standard ISO8601 — ISO8601DateFormatter is UTC by default
        let iso8601 = ISO8601DateFormatter()
        iso8601.timeZone = TimeZone(identifier: "UTC")
        if let date = iso8601.date(from: dateString) { return date }

        // Try ISO8601 with fractional seconds
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601.date(from: dateString) { return date }

        // Try common formats — backend stores UTC, so always parse as UTC
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC") // backend stores UTC
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) { return date }
        }

        return nil
    }

    static func formatDisplayDate(_ dateString: String, format: String = "MMM d, HH:mm") -> String {
        if let date = parseRobustDate(dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = format
            displayFormatter.timeZone = TimeZone.current // display in device local timezone (IST etc.)
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    static func formatDisplayDateShort(_ dateString: String) -> String {
        return formatDisplayDate(dateString, format: "dd MMM, HH:mm")
    }
}
