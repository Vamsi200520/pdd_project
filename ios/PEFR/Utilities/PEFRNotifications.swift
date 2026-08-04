import Foundation

extension Foundation.Notification.Name {
    /// Posted whenever PEFR records change (new record added OR record deleted).
    /// All graph and history views listen to this and reload from the backend.
    static let pefrRecordsDidChange = Foundation.Notification.Name("pefrRecordsDidChange")
}
