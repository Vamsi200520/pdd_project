import Foundation

// MARK: - Medication Models

struct Medication: Codable, Identifiable {
    let id: Int
    let name: String
    let dose: String?
    let schedule: String?
    let description: String?
    let startDate: String?
    let days: Int?
    let cureProbability: Double?
    var dosesRemaining: Int?
    let source: String?
    let prescribedBy: Int?
    let ownerId: Int
    var takenStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, dose, schedule, description, days, source
        case startDate = "start_date"
        case cureProbability = "cure_probability"
        case dosesRemaining = "doses_remaining"
        case prescribedBy = "prescribed_by"
        case ownerId = "owner_id"
        case takenStatus = "taken_status"
    }
}

struct MedicationCreate: Codable {
    let name: String
    let dose: String?
    let schedule: String?
    let description: String?
    let source: String?
    let prescribedBy: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, dose, schedule, description, source
        case prescribedBy = "prescribed_by"
    }
    
    init(name: String, dose: String?, schedule: String?, description: String?, 
         source: String? = nil, prescribedBy: Int? = nil) {
        self.name = name
        self.dose = dose
        self.schedule = schedule
        self.description = description
        self.source = source
        self.prescribedBy = prescribedBy
    }
}

struct MedicationUpdate: Codable {
    let name: String?
    let dose: String?
    let schedule: String?
    let description: String?
    let startDate: String?
    let days: Int?
    let cureProbability: Double?
    let dosesRemaining: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, dose, schedule, description, days
        case startDate = "start_date"
        case cureProbability = "cure_probability"
        case dosesRemaining = "doses_remaining"
    }
    
    init(name: String? = nil, dose: String? = nil, schedule: String? = nil, 
         description: String? = nil, startDate: String? = nil, days: Int? = nil, 
         cureProbability: Double? = nil, dosesRemaining: Int? = nil) {
        self.name = name
        self.dose = dose
        self.schedule = schedule
        self.description = description
        self.startDate = startDate
        self.days = days
        self.cureProbability = cureProbability
        self.dosesRemaining = dosesRemaining
    }
}

struct MedicationTake: Codable {
    let doses: Int
    let notes: String?
    
    init(doses: Int = 1, notes: String? = nil) {
        self.doses = doses
        self.notes = notes
    }
}

struct MedicationStatusUpdate: Codable {
    let status: String
}

struct MedicationStatusHistory: Codable, Identifiable {
    let id: Int
    let medicationId: Int
    let status: String
    let notes: String?
    let changedAt: String
    let changedByUserId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case medicationId = "medication_id"
        case changedAt = "changed_at"
        case changedByUserId = "changed_by_user_id"
    }
}

struct MedicationWithHistory: Codable, Identifiable {
    let id: Int
    let name: String
    let dose: String?
    let schedule: String?
    let description: String?
    let startDate: String?
    let days: Int?
    let cureProbability: Double?
    var dosesRemaining: Int?
    let source: String?
    let prescribedBy: Int?
    let ownerId: Int
    var takenStatus: String?
    let statusHistory: [MedicationStatusHistory]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, dose, schedule, description, days, source
        case startDate = "start_date"
        case cureProbability = "cure_probability"
        case dosesRemaining = "doses_remaining"
        case prescribedBy = "prescribed_by"
        case ownerId = "owner_id"
        case takenStatus = "taken_status"
        case statusHistory = "status_history"
    }
}
