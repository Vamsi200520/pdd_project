import Foundation

// MARK: - PEFR Models

struct BaselinePEFR: Codable, Identifiable {
    let id: Int
    let baselineValue: Int
    let ownerId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case baselineValue = "baseline_value"
        case ownerId = "owner_id"
    }
}

struct BaselinePEFRCreate: Codable {
    let baselineValue: Int
    
    enum CodingKeys: String, CodingKey {
        case baselineValue = "baseline_value"
    }
}

struct PEFRRecord: Codable, Identifiable {
    let id: Int
    let pefrValue: Int
    let zone: String
    let recordedAt: String
    let ownerId: Int
    let percentage: Double?
    let trend: String?
    let source: String?
    
    enum CodingKeys: String, CodingKey {
        case id, zone, percentage, trend, source
        case pefrValue = "pefr_value"
        case recordedAt = "recorded_at"
        case ownerId = "owner_id"
    }
}

struct PEFRRecordCreate: Codable {
    let pefrValue: Int
    let source: String
    
    enum CodingKeys: String, CodingKey {
        case pefrValue = "pefr_value"
        case source
    }
    
    init(pefrValue: Int, source: String = "manual") {
        self.pefrValue = pefrValue
        self.source = source
    }
}

struct PEFRRecordResponse: Codable {
    let zone: String
    let guidance: String
    let record: PEFRRecord
    let percentage: Double?
    let trend: String?
}

// MARK: - Zone Helper
extension PEFRRecord {
    var zoneColor: String {
        switch zone.lowercased() {
        case "green": return "greenZone"
        case "yellow": return "yellowZone"
        case "red": return "redZone"
        default: return "gray"
        }
    }
}
