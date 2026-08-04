import Foundation

// MARK: - Auth Models

struct SignupRequest: Codable {
    let email: String
    let password: String
    let role: String
    let fullName: String?
    let age: Int?
    let height: Int?
    let gender: String?
    let contactInfo: String?
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password, role, age, height, gender, address
        case fullName = "name"
        case contactInfo = "contact_number"
    }
}

struct ProfileUpdateRequest: Codable {
    let password: String?
    let email: String?
    let role: String?
    let fullName: String?
    let age: Int?
    let height: Int?
    let gender: String?
    let contactInfo: String?
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password, role, age, height, gender, address
        case fullName = "name"
        case contactInfo = "contact_number"
    }
    
    init(fullName: String? = nil, age: Int? = nil, height: Int? = nil,
         gender: String? = nil, contactInfo: String? = nil, address: String? = nil) {
        self.password = ""
        self.email = nil
        self.role = nil
        self.fullName = fullName
        self.age = age
        self.height = height
        self.gender = gender
        self.contactInfo = contactInfo
        self.address = address
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let userRole: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case userRole = "user_role"
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let role: String
    let fullName: String?
    let age: Int?
    let height: Int?
    let gender: String?
    let contactInfo: String?
    let address: String?
    let baseline: BaselinePEFR?
    let latestPefrRecord: PEFRRecord?
    let latestSymptom: Symptom?
    
    enum CodingKeys: String, CodingKey {
        case id, email, role, age, height, gender, address, baseline
        case fullName = "name"
        case contactInfo = "contact_number"
        case latestPefrRecord = "latest_pefr_record"
        case latestSymptom = "latest_symptom"
    }
}
