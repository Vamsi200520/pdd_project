import Foundation
import UserNotifications

class LocalNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationManager()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // Allow notifications to show even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    func scheduleReminder(time: Date, frequency: String) {
        // Cancel existing first
        cancelAll()
        
        let content = UNMutableNotificationContent()
        content.title = "PEFR Record Reminder"
        content.body = "Time to track your peak flow and symptoms. Staying consistent helps your doctor monitor your health."
        content.sound = .default
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        if frequency == "Weekly" {
            dateComponents.weekday = calendar.component(.weekday, from: Date())
        } else if frequency == "Monthly" {
            dateComponents.day = calendar.component(.day, from: Date())
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "pefr_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(frequency) at \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
            }
        }
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pefr_reminder"])
        print("All local reminders cancelled.")
    }
}
