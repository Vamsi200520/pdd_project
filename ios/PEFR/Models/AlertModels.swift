import Foundation

struct AlertLog: Codable, Identifiable {
    let id: Int
    let timestamp: String
    let userId: Int
    let alertType: String
    let resolved: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, resolved
        case timestamp
        case userId = "user_id"
        case alertType = "alert_type"
    }
}
