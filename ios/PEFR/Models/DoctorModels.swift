import Foundation

// MARK: - Doctor-Patient Link Models

struct DoctorPatientLink: Codable, Identifiable {
    let id: Int
    let doctorId: Int
    let patientId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case doctorId = "doctor_id"
        case patientId = "patient_id"
    }
}

struct DoctorPatientLinkRequest: Codable {
    let doctorEmail: String
    
    enum CodingKeys: String, CodingKey {
        case doctorEmail = "doctor_email"
    }
}

// MARK: - ML Models

struct MLInput: Codable {
    let age: Int?
    let pefrValue: Int
    let wheezeRating: Int?
    let coughRating: Int?
    let dustExposure: Bool?
    let smokeExposure: Bool?
    
    enum CodingKeys: String, CodingKey {
        case age
        case pefrValue = "pefr_value"
        case wheezeRating = "wheeze_rating"
        case coughRating = "cough_rating"
        case dustExposure = "dust_exposure"
        case smokeExposure = "smoke_exposure"
    }
}

struct MLPrediction: Codable {
    let recommendedMedicine: String
    let recommendedDays: Int
    let predictedCureProbability: Double
    
    enum CodingKeys: String, CodingKey {
        case recommendedMedicine = "recommended_medicine"
        case recommendedDays = "recommended_days"
        case predictedCureProbability = "predicted_cure_probability"
    }
}

// MARK: - Notification Model

struct Notification: Codable, Identifiable {
    let id: Int
    let ownerId: Int
    let message: String
    let link: String?
    let createdAt: String
    let read: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, message, link, read
        case ownerId = "owner_id"
        case createdAt = "created_at"
    }
}
