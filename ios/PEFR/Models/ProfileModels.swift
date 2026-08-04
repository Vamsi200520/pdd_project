import Foundation

// MARK: - Profile Models

struct EmergencyContact: Codable, Identifiable {
    let id: Int
    let name: String
    let phoneNumber: String
    let contactRelationship: String?
    let ownerId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case phoneNumber = "phone_number"
        case contactRelationship = "contact_relationship"
        case ownerId = "owner_id"
    }
}

struct EmergencyContactCreate: Codable {
    let name: String
    let phoneNumber: String
    let contactRelationship: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case phoneNumber = "phone_number"
        case contactRelationship = "contact_relationship"
    }
}

struct Reminder: Codable, Identifiable {
    let id: Int
    let reminderType: String
    let time: String
    let frequency: String
    let complianceCount: Int
    let missedCount: Int
    let ownerId: Int
    
    enum CodingKeys: String, CodingKey {
        case id, time, frequency
        case reminderType = "reminder_type"
        case complianceCount = "compliance_count"
        case missedCount = "missed_count"
        case ownerId = "owner_id"
    }
}

struct ReminderCreate: Codable {
    let reminderType: String
    let time: String
    let frequency: String
    
    enum CodingKeys: String, CodingKey {
        case time, frequency
        case reminderType = "reminder_type"
    }
}
