import SwiftUI

struct GraphView: View {
    @Binding var showMenu: Bool
    var patientId: Int? = nil
    var preloadedPefrRecord: PEFRRecord? = nil   // ← passed from dashboard
    @State private var records: [PEFRRecord] = []
    @State private var symptoms: [Symptom] = []
    @State private var isLoading = true
    @State private var showWeekly = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToHistory = false
    @State private var baseline: Int = 450
    @State private var patientName: String? = nil
    
    // Local Dismissal
    @State private var dismissedPefrIds: Set<Int> = []
    @State private var dismissedSymptomIds: Set<Int> = []
    
    private var dismissedPefrKey: String {
        if let pid = patientId { return "doctor_dismissed_pefr_\(pid)" }
        return "patient_dismissed_pefr"
    }
    
    private var dismissedSymptomKey: String {
        if let pid = patientId { return "doctor_dismissed_symptoms_\(pid)" }
        return "patient_dismissed_symptoms"
    }
    
    init(showMenu: Binding<Bool>, patientId: Int? = nil, patientName: String? = nil, preloadedPefrRecord: PEFRRecord? = nil, preloadedSymptom: Symptom? = nil) {
        self._showMenu = showMenu
        self.patientId = patientId
        self.preloadedPefrRecord = preloadedPefrRecord
        self._patientName = State(initialValue: patientName)
        // Default to weekly view for everyone
        self._showWeekly = State(initialValue: true)
        
        // Initialize symptoms with preloaded data if available
        if let symptom = preloadedSymptom {
            self._symptoms = State(initialValue: [symptom])
        }
    }
    
    // Build 7 synthetic daily records from a single known value (used as average)
    private func syntheticRecords(from record: PEFRRecord) -> [PEFRRecord] {
        let avg = record.pefrValue
        // Small integer offsets around the average to mimic realistic variation
        let offsets = [-15, 10, -5, 20, -10, 5, 0]
        let calendar = Calendar.current
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return offsets.enumerated().compactMap { (i, offset) -> PEFRRecord? in
            guard let date = calendar.date(byAdding: .day, value: -(6 - i), to: Date()) else { return nil }
            let value = max(50, avg + offset)
            let zone: String
            let pct = avg > 0 ? Double(value) / Double(avg) * 100 : 80
            if pct >= 80 { zone = "green" }
            else if pct >= 50 { zone = "yellow" }
            else { zone = "red" }
            return PEFRRecord(
                id: i + 90000,
                pefrValue: value,
                zone: zone,
                recordedAt: isoFormatter.string(from: date),
                ownerId: record.ownerId,
                percentage: pct,
                trend: nil,
                source: "estimated"
            )
        }
    }
    
    private var isDoctorMode: Bool { patientId != nil }
    
    var body: some View {
        ZStack {
            Color.primaryColor.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("PEFR Graph")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "#2C5E5E"))
                                
                                if let preloaded = preloadedPefrRecord {
                                    Spacer()
                                    Text("Avg: \(preloaded.pefrValue) L/min")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#2C5E5E").opacity(0.75))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                            
                            PEFRGraphView(
                                records: filteredRecords,
                                baseline: baseline,
                                isWeekly: $showWeekly
                            )
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                        
                        // 2. Symptoms Section
                        Text("Recent Symptoms")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        VStack(spacing: 12) {
                            let filteredSymptoms = symptoms.filter { !dismissedSymptomIds.contains($0.id) }
                            if filteredSymptoms.isEmpty {
                                Text("No recent symptoms recorded.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                            } else {
                                ForEach(filteredSymptoms.prefix(10)) { symptom in
                                    SymptomRow(symptom: symptom)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 3. View History Button
                        Button(action: {
                            navigateToHistory = true
                        }) {
                            Text("View History")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "#50B5A6"))
                                .cornerRadius(28)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    loadData()
                }
            }
        }
        .navigationTitle(isDoctorMode ? (patientName ?? "Patient Graph") : "Graph")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Deleted hamburger menu to restrict drawer access to the dashboard only.
        }
        .onAppear(perform: loadData)
        .onReceive(NotificationCenter.default.publisher(for: Foundation.Notification.Name("pefrRecordsDidChange"))) { _ in
            // Only auto-reload in patient mode;
            // doctor view is separately navigated and refreshes on appear
            if !isDoctorMode {
                records = []
                loadData()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToHistory) {
            HistoryListView(patientId: patientId)
        }
    }
    private var filteredRecords: [PEFRRecord] {
        let now = Date()
        let calendar = Calendar.current
        let daysAgo = showWeekly ? 7 : 30

        let filtered = records.filter { record in
            if dismissedPefrIds.contains(record.id) { return false }
            guard let date = DateUtils.parseRobustDate(record.recordedAt) else { return false }
            let diff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return diff <= daysAgo
        }

        return filtered.sorted { record1, record2 in
             (DateUtils.parseRobustDate(record1.recordedAt) ?? Date()) <
             (DateUtils.parseRobustDate(record2.recordedAt) ?? Date())
        }
    }
    
    private func loadData() {
        // Always fetch fresh data from backend — do NOT use preloaded/synthetic records.
        // Preloaded data can be stale (e.g. user deleted records in History).
        Task {
            if let patientId = patientId {
                // Load dismissed IDs for this specific patient (Doctor Mode persistence)
                if let savedSymptoms = UserDefaults.standard.array(forKey: dismissedSymptomKey) as? [Int] {
                    self.dismissedSymptomIds = Set(savedSymptoms)
                }

                // Fetch Profile
                Task {
                    do {
                        let profile = try await APIService.shared.getPatientProfile(patientId: patientId)
                        await MainActor.run {
                            self.baseline = profile.baseline?.baselineValue ?? 450
                            self.patientName = profile.fullName
                            if let latestSymptom = profile.latestSymptom, self.symptoms.isEmpty {
                                // If latestSymptom is dismissed, don't show it as the initial state
                                if !self.dismissedSymptomIds.contains(latestSymptom.id) {
                                    self.symptoms = [latestSymptom]
                                }
                            }
                        }
                    } catch { print("Profile fetch failed: \(error)") }
                }
                
                // Fetch PEFR Records
                Task {
                    do {
                        let pefrData = try await APIService.shared.getPatientPefrRecords(patientId: patientId)
                        await MainActor.run {
                            if !pefrData.isEmpty { self.records = pefrData }
                        }
                    } catch { print("PEFR fetch failed: \(error)") }
                }
                
                // Fetch Symptoms
                Task {
                    do {
                        let symptomData = try await APIService.shared.getPatientSymptomRecords(patientId: patientId)
                        await MainActor.run {
                            if !symptomData.isEmpty {
                                self.symptoms = symptomData.sorted(by: { 
                                    (DateUtils.parseRobustDate($0.recordedAt) ?? Date()) > (DateUtils.parseRobustDate($1.recordedAt) ?? Date()) 
                                })
                            }
                            self.isLoading = false
                        }
                    } catch { 
                        print("Symptom fetch failed: \(error)") 
                        await MainActor.run { self.isLoading = false }
                    }
                }
            } else {
                // Patient mode - always fetch latest from backend
                do {
                    async let profileReq = APIService.shared.getMyProfile()
                    async let pefrReq = APIService.shared.getMyPefrRecords()
                    async let symptomReq = APIService.shared.getMySymptomRecords()
                    async let dismissedSymptomReq = APIService.shared.getDismissedSymptomIds()
                    async let dismissedPefrReq = APIService.shared.getDismissedPefrIds()

                    let (profile, pefrData, symptomData, dismissedSymptomIdsList, dismissedPefrIdsList) = try await (profileReq, pefrReq, symptomReq, dismissedSymptomReq, dismissedPefrReq)

                    await MainActor.run {
                        self.baseline = profile.baseline?.baselineValue ?? 450
                        self.records = pefrData
                        self.symptoms = symptomData.sorted(by: {
                            (DateUtils.parseRobustDate($0.recordedAt) ?? Date()) >
                            (DateUtils.parseRobustDate($1.recordedAt) ?? Date())
                        })

                        // Sync dismissed symptom IDs
                        let localSymptomIds = UserDefaults.standard.array(forKey: dismissedSymptomKey) as? [Int] ?? []
                        let mergedSymptomIds = Set(dismissedSymptomIdsList).union(localSymptomIds)
                        self.dismissedSymptomIds = mergedSymptomIds
                        UserDefaults.standard.set(Array(mergedSymptomIds), forKey: dismissedSymptomKey)
                        
                        // Push new local symptom dismissals to backend
                        if mergedSymptomIds.count > dismissedSymptomIdsList.count {
                            Task {
                                for id in localSymptomIds {
                                    if !dismissedSymptomIdsList.contains(id) {
                                        await APIService.shared.dismissSymptomId(id: id)
                                    }
                                }
                            }
                        }

                        // Sync dismissed PEFR IDs
                        let localPefrIds = UserDefaults.standard.array(forKey: dismissedPefrKey) as? [Int] ?? []
                        let mergedPefrIds = Set(dismissedPefrIdsList).union(localPefrIds)
                        self.dismissedPefrIds = mergedPefrIds
                        UserDefaults.standard.set(Array(mergedPefrIds), forKey: dismissedPefrKey)
                        
                        // Push new local PEFR dismissals to backend
                        if mergedPefrIds.count > dismissedPefrIdsList.count {
                            Task {
                                for id in localPefrIds {
                                    if !dismissedPefrIdsList.contains(id) {
                                        await APIService.shared.dismissPefrId(id: id)
                                    }
                                }
                            }
                        }

                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showError = true
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func deleteSymptom(_ symptom: Symptom) {
        withAnimation {
            dismissedSymptomIds.insert(symptom.id)
            UserDefaults.standard.set(Array(dismissedSymptomIds), forKey: dismissedSymptomKey)
            // Also remove from local array for immediate UI feedback
            symptoms.removeAll(where: { $0.id == symptom.id })
        }
        
        if !isDoctorMode {
            Task {
                await APIService.shared.dismissSymptomId(id: symptom.id)
            }
        }
    }
}

// SymptomRow remains defined here or in a component file
// Refined to match the Android-style compact representation
struct SymptomRow: View {
    let symptom: Symptom
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Severity Indicator
            Circle()
                .fill(severityColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(formatDate(symptom.recordedAt)): \(symptomSummary)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Delete Button (Local Dismissal)
            if let onDelete = onDelete {
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.4))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Remove Locally", systemImage: "trash")
                }
            }
        }
    }
    
    private var symptomSummary: String {
        var summary: [String] = []
        if let s = symptom.severity, !s.isEmpty { summary.append(s) }
        if let w = symptom.wheezeRating { summary.append("Wheeze: \(w)") }
        if let c = symptom.coughRating { summary.append("Cough: \(c)") }
        if let d = symptom.dyspneaRating { summary.append("Breath: \(d)") }
        if let n = symptom.nightSymptomsRating { summary.append("Night: \(n)") }
        if let ct = symptom.chestTightnessRating { summary.append("Chest: \(ct)") }
        if let al = symptom.activityLimitationRating { summary.append("Activity: \(al)") }
        if let p = symptom.rescueInhalerPuffs { summary.append("Puffs: \(p)") }
        
        let result = summary.joined(separator: ", ")
        return result.isEmpty ? "No rating specified" : result
    }
    
    private var severityColor: Color {
        let maxRating = [
            symptom.wheezeRating, 
            symptom.coughRating, 
            symptom.dyspneaRating, 
            symptom.nightSymptomsRating,
            symptom.chestTightnessRating,
            symptom.activityLimitationRating
        ]
            .compactMap({ $0 })
            .max() ?? 0
            
        if maxRating >= 4 { return .redZone }
        if maxRating >= 2 { return .yellowZone }
        return .greenZone
    }
    
    private func formatDate(_ dateString: String) -> String {
        return DateUtils.formatDisplayDateShort(dateString)
    }
}
