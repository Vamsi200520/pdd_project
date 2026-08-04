import Foundation

// MARK: - Symptom Models

struct Symptom: Codable, Identifiable {
    let id: Int
    let recordedAt: String
    let ownerId: Int
    let wheezeRating: Int?
    let coughRating: Int?
    let dustExposure: Bool?
    let smokeExposure: Bool?
    let dyspneaRating: Int?
    let nightSymptomsRating: Int?
    let chestTightnessRating: Int?
    let activityLimitationRating: Int?
    let rescueInhalerPuffs: Int?
    let severity: String?
    let onsetAt: String?
    let duration: Int?
    let suspectedTrigger: String?
    
    enum CodingKeys: String, CodingKey {
        case id, severity, duration
        case recordedAt = "recorded_at"
        case ownerId = "owner_id"
        case wheezeRating = "wheeze_rating"
        case coughRating = "cough_rating"
        case dustExposure = "dust_exposure"
        case smokeExposure = "smoke_exposure"
        case dyspneaRating = "dyspnea_rating"
        case nightSymptomsRating = "night_symptoms_rating"
        case chestTightnessRating = "chest_tightness_rating"
        case activityLimitationRating = "activity_limitation_rating"
        case rescueInhalerPuffs = "rescue_inhaler_puffs"
        case onsetAt = "onset_at"
        case suspectedTrigger = "suspected_trigger"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try decoder.container(keyedBy: CustomCodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        recordedAt = try container.decode(String.self, forKey: .recordedAt)
        ownerId = try container.decode(Int.self, forKey: .ownerId)
        
        // Use a robust helper for all ratings to handle both key variations and type mismatches (Int/String/Double)
        wheezeRating = Symptom.decodeInt(container, raw, key: .wheezeRating, fallbacks: [.wheeze])
        coughRating = Symptom.decodeInt(container, raw, key: .coughRating, fallbacks: [.cough])
        dyspneaRating = Symptom.decodeInt(container, raw, key: .dyspneaRating, fallbacks: [.dyspnea, .breath])
        nightSymptomsRating = Symptom.decodeInt(container, raw, key: .nightSymptomsRating, fallbacks: [.nightSymptoms])
        chestTightnessRating = Symptom.decodeInt(container, raw, key: .chestTightnessRating, fallbacks: [.chestTightness, .chest])
        activityLimitationRating = Symptom.decodeInt(container, raw, key: .activityLimitationRating, fallbacks: [.activityLimitation, .activity])
        rescueInhalerPuffs = Symptom.decodeInt(container, raw, key: .rescueInhalerPuffs, fallbacks: [.puffs, .rescuePuffs])
        
        dustExposure = try? container.decodeIfPresent(Bool.self, forKey: .dustExposure)
        smokeExposure = try? container.decodeIfPresent(Bool.self, forKey: .smokeExposure)
        severity = try? container.decodeIfPresent(String.self, forKey: .severity)
        onsetAt = try? container.decodeIfPresent(String.self, forKey: .onsetAt)
        duration = try? container.decodeIfPresent(Int.self, forKey: .duration)
        suspectedTrigger = try? container.decodeIfPresent(String.self, forKey: .suspectedTrigger)
    }
    
    // Failsafe helper to decode Int from various possible types and keys
    private static func decodeInt(_ container: KeyedDecodingContainer<CodingKeys>, _ raw: KeyedDecodingContainer<CustomCodingKeys>, key: CodingKeys, fallbacks: [CustomCodingKeys]) -> Int? {
        // 1. Try primary key
        if let val = tryDecode(container, key: key) { return val }
        
        // 2. Try fallback keys
        for fk in fallbacks {
            if let val = tryDecode(raw, key: fk) { return val }
        }
        return nil
    }
    
    private static func tryDecode<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int? {
        // Try Int
        if let val = try? container.decodeIfPresent(Int.self, forKey: key) { return val }
        // Try String
        if let str = try? container.decodeIfPresent(String.self, forKey: key), let val = Int(str) { return val }
        // Try Double/Float
        if let dbl = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(dbl) }
        return nil
    }
    
    private enum CustomCodingKeys: String, CodingKey {
        case wheeze = "wheeze"
        case cough = "cough"
        case dyspnea = "dyspnea"
        case breath = "breath"
        case nightSymptoms = "night_symptoms"
        case chestTightness = "chest_tightness"
        case chest = "chest"
        case activityLimitation = "activity_limitation"
        case activity = "activity"
        case rescuePuffs = "rescue_puffs"
        case puffs = "puffs"
    }
}

struct SymptomCreate: Codable {
    let wheezeRating: Int?
    let coughRating: Int?
    let dustExposure: Bool?
    let smokeExposure: Bool?
    let dyspneaRating: Int?
    let nightSymptomsRating: Int?
    let chestTightnessRating: Int?
    let activityLimitationRating: Int?
    let rescueInhalerPuffs: Int?
    let severity: String?
    let onsetAt: String?
    let duration: Int?
    let suspectedTrigger: String?
    
    enum CodingKeys: String, CodingKey {
        case severity, duration
        case wheezeRating = "wheeze_rating"
        case coughRating = "cough_rating"
        case dustExposure = "dust_exposure"
        case smokeExposure = "smoke_exposure"
        case dyspneaRating = "dyspnea_rating"
        case nightSymptomsRating = "night_symptoms_rating"
        case chestTightnessRating = "chest_tightness_rating"
        case activityLimitationRating = "activity_limitation_rating"
        case rescueInhalerPuffs = "rescue_inhaler_puffs"
        case onsetAt = "onset_at"
        case suspectedTrigger = "suspected_trigger"
    }
}
