import Foundation

// API Service wrapping NetworkManager with typed endpoints
class APIService {
    static let shared = APIService()
    private let network = NetworkManager.shared
    
    private init() {}
    
    // MARK: - Auth
    
    func login(email: String, password: String) async throws -> TokenResponse {
        return try await network.formRequest(
            endpoint: "auth/login",
            parameters: ["username": email, "password": password]
        )
    }
    
    func signup(request: SignupRequest) async throws -> User {
        return try await network.request(
            endpoint: "auth/signup",
            method: .POST,
            body: request,
            requiresAuth: false
        )
    }
    
    func signupSendOtp(request: SignupRequest) async throws -> [String: String] {
        return try await network.request(
            endpoint: "auth/signup-send-otp",
            method: .POST,
            body: request,
            requiresAuth: false
        )
    }
    
    func verifySignupOtp(email: String, otp: String) async throws -> [String: String] {
        return try await network.formRequest(
            endpoint: "auth/verify-signup-otp",
            parameters: ["email": email, "otp": otp]
        )
    }
    
    func forgotPassword(email: String) async throws -> [String: String] {
        return try await network.formRequest(
            endpoint: "auth/forgot-password",
            parameters: ["email": email]
        )
    }
    
    func resetPassword(email: String, otp: String, newPassword: String) async throws -> [String: String] {
        return try await network.formRequest(
            endpoint: "auth/reset-password",
            parameters: ["email": email, "otp": otp, "new_password": newPassword]
        )
    }
    
    func verifyForgotOtp(email: String, otp: String) async throws -> [String: String] {
        return try await network.formRequest(
            endpoint: "auth/verify-forgot-otp",
            parameters: ["email": email, "otp": otp]
        )
    }
    
    // MARK: - Profile
    
    func getMyProfile() async throws -> User {
        return try await network.request(endpoint: "profile/me")
    }
    
    func updateMyProfile(request: ProfileUpdateRequest, userEmail: String, userRole: String) async throws -> User {
        // The live backend PUT /profile/me uses UserCreate schema which requires
        // email, name, role, password. Build a complete payload to satisfy it.
        struct FullProfileUpdate: Codable {
            let email: String
            let name: String
            let role: String
            let password: String    // Required field; send empty string (backend skips hashing if empty)
            let age: Int?
            let height: Int?
            let gender: String?
            let contact_number: String?
            let address: String?
        }
        
        let fullRequest = FullProfileUpdate(
            email: userEmail,
            name: request.fullName ?? "",
            role: userRole,
            password: "",
            age: request.age,
            height: request.height,
            gender: request.gender,
            contact_number: request.contactInfo,
            address: request.address
        )
        
        // Confirm the PUT succeeded (id field is always in the response)
        struct PutResponse: Codable { let id: Int }
        let _: PutResponse = try await network.request(
            endpoint: "profile/me",
            method: .PUT,
            body: fullRequest
        )
        // Re-fetch via GET to get a fully-populated User (with baseline, latestPefrRecord, etc.)
        return try await getMyProfile()
    }
    
    func registerDeviceToken(token: String) async throws -> [String: String] {
        return try await network.formRequest(
            endpoint: "profile/device-token",
            parameters: ["token": token],
            requiresAuth: true
        )
    }
    
    func deleteMyAccount() async throws -> [String: String] {
        return try await network.request(endpoint: "profile/me", method: .DELETE)
    }
    
    // MARK: - Baseline
    
    func setBaseline(baselineValue: Int) async throws -> BaselinePEFR {
        return try await network.request(
            endpoint: "patient/baseline",
            method: .POST,
            body: BaselinePEFRCreate(baselineValue: baselineValue)
        )
    }
    
    // MARK: - PEFR
    
    func recordPEFR(pefrValue: Int) async throws -> PEFRRecordResponse {
        return try await network.request(
            endpoint: "pefr/record",
            method: .POST,
            body: PEFRRecordCreate(pefrValue: pefrValue)
        )
    }
    
    func getMyPefrRecords() async throws -> [PEFRRecord] {
        return try await network.request(endpoint: "pefr/records")
    }
    
    func deletePEFRRecord(id: Int) async throws {
        // Backend returns {"message": "..."} or {"detail": "Not Found"} on 404.
        // Use a response struct with an optional message to avoid decode errors.
        struct DeleteResponse: Codable { let message: String? }
        do {
            let _: DeleteResponse = try await network.request(
                endpoint: "pefr/records/\(id)",
                method: .DELETE
            )
        } catch {
            // If the backend says the record was not found (404), it is already
            // gone — treat this as a successful delete so the UI stays clean.
            let desc = error.localizedDescription.lowercased()
            if desc.contains("not found") || desc.contains("404") ||
               desc.contains("pefr record not found") {
                return
            }
            throw error
        }
    }
    
    // MARK: - Alerts
    
    func getAlerts() async throws -> [AlertLog] {
        return try await network.request(endpoint: "alerts")
    }
    
    // MARK: - Symptoms
    
    func recordSymptom(request: SymptomCreate) async throws -> Symptom {
        return try await network.request(
            endpoint: "symptom/record",
            method: .POST,
            body: request
        )
    }

    func getMySymptomRecords() async throws -> [Symptom] {
        return try await network.request(endpoint: "symptom/records")
    }
    
    func deleteSymptomRecord(id: Int) async throws {
        struct Response: Codable {}
        let _: Response = try await network.request(
            endpoint: "symptom/records/\(id)",
            method: .DELETE
        )
    }
    
    // MARK: - Medications
    
    func getMedications() async throws -> [Medication] {
        let allMeds: [Medication] = try await network.request(endpoint: "medications")
        return allMeds.filter { $0.name != "__dismissed_symptoms__" && $0.name != "__dismissed_pefr__" }
    }

    func getDismissedSymptomIds() async -> [Int] {
        do {
            let allMeds: [Medication] = try await network.request(endpoint: "medications")
            if let dummy = allMeds.first(where: { $0.name == "__dismissed_symptoms__" }),
               let doseStr = dummy.dose {
                return doseStr.components(separatedBy: ",").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
        } catch {
            print("Failed to fetch dismissed symptom IDs: \(error)")
        }
        return []
    }
    
    func dismissSymptomId(id: Int) async {
        do {
            let allMeds: [Medication] = try await network.request(endpoint: "medications")
            let dummy = allMeds.first(where: { $0.name == "__dismissed_symptoms__" })
            
            var dismissedIds: [String] = []
            if let doseStr = dummy?.dose {
                dismissedIds = doseStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
            
            let idStr = String(id)
            if !dismissedIds.contains(idStr) {
                dismissedIds.append(idStr)
            }
            
            let newDose = dismissedIds.joined(separator: ",")
            
            if let existing = dummy {
                let _: Medication = try await network.request(
                    endpoint: "medications/\(existing.id)",
                    method: .PATCH,
                    body: MedicationUpdate(dose: newDose)
                )
            } else {
                let _: Medication = try await network.request(
                    endpoint: "medications",
                    method: .POST,
                    body: MedicationCreate(name: "__dismissed_symptoms__", dose: newDose, schedule: "meta", description: "meta")
                )
            }
        } catch {
            print("Failed to dismiss symptom ID \(id): \(error)")
        }
    }

    func getDismissedPefrIds() async -> [Int] {
        do {
            let allMeds: [Medication] = try await network.request(endpoint: "medications")
            if let dummy = allMeds.first(where: { $0.name == "__dismissed_pefr__" }),
               let doseStr = dummy.dose {
                return doseStr.components(separatedBy: ",").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            }
        } catch {
            print("Failed to fetch dismissed PEFR IDs: \(error)")
        }
        return []
    }
    
    func dismissPefrId(id: Int) async {
        do {
            let allMeds: [Medication] = try await network.request(endpoint: "medications")
            let dummy = allMeds.first(where: { $0.name == "__dismissed_pefr__" })
            
            var dismissedIds: [String] = []
            if let doseStr = dummy?.dose {
                dismissedIds = doseStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
            
            let idStr = String(id)
            if !dismissedIds.contains(idStr) {
                dismissedIds.append(idStr)
            }
            
            let newDose = dismissedIds.joined(separator: ",")
            
            if let existing = dummy {
                let _: Medication = try await network.request(
                    endpoint: "medications/\(existing.id)",
                    method: .PATCH,
                    body: MedicationUpdate(dose: newDose)
                )
            } else {
                let _: Medication = try await network.request(
                    endpoint: "medications",
                    method: .POST,
                    body: MedicationCreate(name: "__dismissed_pefr__", dose: newDose, schedule: "meta", description: "meta")
                )
            }
        } catch {
            print("Failed to dismiss PEFR ID \(id): \(error)")
        }
    }
    
    func addMedication(request: MedicationCreate) async throws -> Medication {
        return try await network.request(
            endpoint: "medications",
            method: .POST,
            body: request
        )
    }
    
    func updateMedication(id: Int, request: MedicationUpdate) async throws -> Medication {
        return try await network.request(
            endpoint: "medications/\(id)",
            method: .PATCH,
            body: request
        )
    }
    
    func updateMedicationStatus(id: Int, status: String) async throws {
        struct Response: Codable {}
        let _: Response = try await network.request(
            endpoint: "medications/\(id)/status",
            method: .PATCH,
            body: MedicationStatusUpdate(status: status)
        )
    }
    
    func takeMedication(id: Int, doses: Int = 1) async throws -> Medication {
        return try await network.request(
            endpoint: "medications/\(id)/take",
            method: .POST,
            body: MedicationTake(doses: doses)
        )
    }
    
    func deleteMedication(id: Int) async throws {
        struct Response: Codable {}
        let _: Response = try await network.request(
            endpoint: "medications/\(id)",
            method: .DELETE
        )
    }
    
    // MARK: - ML
    
    func mlPredict(input: MLInput) async throws -> MLPrediction {
        return try await network.request(
            endpoint: "ml/predict",
            method: .POST,
            body: input
        )
    }
    
    // MARK: - Doctor
    
    func getDoctorPatients(search: String? = nil, zone: String? = nil) async throws -> [User] {
        var endpoint = "doctor/patients"
        var queryItems: [String] = []
        if let search = search { queryItems.append("search=\(search)") }
        if let zone = zone { queryItems.append("zone=\(zone)") }
        if !queryItems.isEmpty { endpoint += "?" + queryItems.joined(separator: "&") }
        
        return try await network.request(endpoint: endpoint)
    }
    
    func linkDoctor(doctorEmail: String) async throws -> DoctorPatientLink {
        return try await network.request(
            endpoint: "patient/link-doctor",
            method: .POST,
            body: DoctorPatientLinkRequest(doctorEmail: doctorEmail)
        )
    }
    
    func getLinkedDoctor() async throws -> User {
        return try await network.request(endpoint: "patient/doctor")
    }
    
    func unlinkDoctor() async throws {
        struct Response: Codable {}
        let _: Response = try await network.request(endpoint: "patient/doctor", method: .DELETE)
    }
    
    func getPatientProfile(patientId: Int) async throws -> User {
        return try await network.request(endpoint: "patient/\(patientId)/profile")
    }
    
    func getPatientPefrRecords(patientId: Int) async throws -> [PEFRRecord] {
        return try await network.request(endpoint: "patient/\(patientId)/pefr")
    }
    
    func getPatientSymptomRecords(patientId: Int) async throws -> [Symptom] {
        return try await network.request(endpoint: "patient/\(patientId)/symptoms")
    }
    
    func getPatientMedications(patientId: Int) async throws -> [Medication] {
        let allMeds: [Medication] = try await network.request(endpoint: "patient/\(patientId)/medications")
        return allMeds.filter { $0.name != "__dismissed_symptoms__" && $0.name != "__dismissed_pefr__" }
    }
    
    func prescribeMedication(patientId: Int, request: MedicationCreate) async throws -> Medication {
        return try await network.request(
            endpoint: "doctor/patient/\(patientId)/medication",
            method: .POST,
            body: request
        )
    }
    
    func deleteLinkedPatient(patientId: Int) async throws {
        struct Response: Codable {}
        let _: Response = try await network.request(
            endpoint: "doctor/patient/\(patientId)",
            method: .DELETE
        )
    }
    
    func getMedicationHistory(patientId: Int) async throws -> [MedicationWithHistory] {
        return try await network.request(endpoint: "doctor/patient/\(patientId)/medications/history")
    }
    
    // MARK: - Reminders
    
    func getReminders() async throws -> [Reminder] {
        return try await network.request(endpoint: "reminders")
    }
    
    func createReminder(request: ReminderCreate) async throws -> Reminder {
        return try await network.request(
            endpoint: "reminders",
            method: .POST,
            body: request
        )
    }
    
    // MARK: - Emergency Contacts
    
    func getEmergencyContacts() async throws -> [EmergencyContact] {
        return try await network.request(endpoint: "contacts/emergency")
    }
    
    // MARK: - Notifications
    
    func getNotifications() async throws -> [Notification] {
        return try await network.request(endpoint: "notifications")
    }
    
    func markNotificationRead(id: Int) async throws -> Notification {
        return try await network.request(
            endpoint: "notifications/\(id)/read",
            method: .PATCH
        )
    }

    func deleteNotification(id: Int) async throws {
        struct Response: Codable {}
        let _: Response = try await network.request(
            endpoint: "notifications/\(id)",
            method: .DELETE
        )
    }
}
