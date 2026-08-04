import SwiftUI

struct HomeDashboardView: View {
    @Binding var showMenu: Bool
    @State private var user: User?
    @State private var recentPefrRecords: [PEFRRecord] = []
    @State private var recentSymptoms: [Symptom] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showWeekly = true
    @State private var showFullScreenGraph = false
    
    // Symptom local dismissal (symptoms are hidden locally, not deleted from backend)
    @State private var dismissedSymptomIds: Set<Int> = []
    private let dismissedSymptomKey = "patient_dismissed_symptoms"

    @State private var dismissedPefrIds: Set<Int> = []
    private let dismissedPefrKey = "patient_dismissed_pefr"

    private var filteredRecentPefr: [PEFRRecord] {
        let now = Date()
        let calendar = Calendar.current
        let daysAgo = showWeekly ? 7 : 30
        
        let filtered = recentPefrRecords.filter { record in
            if dismissedPefrIds.contains(record.id) { return false }
            guard let date = DateUtils.parseRobustDate(record.recordedAt) else { return false }
            let diff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return diff <= daysAgo
        }
        
        // Return filtered records sorted by date ascending for the graph
        return filtered.sorted { (DateUtils.parseRobustDate($0.recordedAt) ?? Date()) < (DateUtils.parseRobustDate($1.recordedAt) ?? Date()) }
    }
    private var filteredRecentSymptoms: [Symptom] {
        recentSymptoms.filter { !dismissedSymptomIds.contains($0.id) }
    }
    
    var body: some View {
        ZStack {
            Color.primaryColor.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 1. Profile Welcome Header
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: .black.opacity(0.1), radius: 4)
                                
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .cornerRadius(6)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Welcome, \(user?.fullName ?? "User")")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 2. Title "Home"
                        Text("Home")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        // 3. Graph Card
                        VStack(spacing: 0) {
                            PEFRGraphView(
                                records: filteredRecentPefr,
                                baseline: user?.baseline?.baselineValue ?? 450,
                                isWeekly: $showWeekly,
                                showLine: true
                            )
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(28)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showFullScreenGraph = true
                            }
                        }
                        
                        // 4. Today's Zone Card
                        zoneCard
                            .padding(.horizontal, 20)
                        
                        // 5. Recent Symptoms Section
                        if !filteredRecentSymptoms.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Symptoms")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ForEach(filteredRecentSymptoms.prefix(3)) { symptom in
                                    SymptomRow(symptom: symptom)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        
                        // Action Buttons Section
                        HStack(spacing: 16) {
                            NavigationLink(destination: PEFRInputView()) {
                                VStack(spacing: 8) {
                                    Image(systemName: "lungs.fill")
                                        .font(.system(size: 24))
                                    Text("Record PEFR")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 90)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                            }
                            
                            NavigationLink(destination: SymptomTrackerView()) {
                                VStack(spacing: 8) {
                                    Image(systemName: "list.bullet.clipboard.fill")
                                        .font(.system(size: 24))
                                    Text("Track Symptoms")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 90)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer().frame(height: 120)
                    }
                }
                .blur(radius: showFullScreenGraph ? 15 : 0)
                .animation(.easeInOut, value: showFullScreenGraph)
                .refreshable {
                    loadData()
                }
            }
            
            // Pop-up Overlay
            if showFullScreenGraph {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showFullScreenGraph = false }
                    }
                
                FullScreenGraphView(
                    records: filteredRecentPefr,
                    baseline: user?.baseline?.baselineValue ?? 450,
                    isWeekly: $showWeekly,
                    showFullScreenGraph: $showFullScreenGraph
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle("Home Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation { showMenu = true }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Clear PEFR records so deleted entries are not shown while fresh data loads
            recentPefrRecords = []
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Foundation.Notification.Name("pefrRecordsDidChange"))) { _ in
            // Reload when records are added (new PEFR) or deleted (from History)
            recentPefrRecords = []
            loadData()
        }
    }
    
    private var zoneCard: some View {
        let latestPefr = filteredRecentPefr.sorted(by: { $0.recordedAt > $1.recordedAt }).first
        let baseline = user?.baseline?.baselineValue ?? 450
        let pefrValue = latestPefr?.pefrValue ?? 0
        let percentage = baseline > 0 ? (Double(pefrValue) / Double(baseline) * 100) : 0
        
        let zoneData = getZoneInfo(percentage: percentage)
        
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Today's Zone")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text(zoneData.status.uppercased())
                    .font(.system(size: 16, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
            }
            .foregroundColor(.white)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(pefrValue)")
                    .font(.system(size: 80, weight: .bold))
                
                Text("(\(Int(percentage))%)")
                    .font(.system(size: 28, weight: .bold))
            }
            .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Last recorded: \(latestPefr != nil ? formatDate(latestPefr!.recordedAt) : "N/A")")
                    .font(.system(size: 14, weight: .medium))
                    .opacity(0.9)
                
                Text(zoneData.guidance)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(zoneData.color)
        .cornerRadius(28)
        .shadow(color: zoneData.color.opacity(0.3), radius: 10, y: 5)
    }
    
    struct ZoneInfo {
        let color: Color
        let status: String
        let guidance: String
    }
    
    private func getZoneInfo(percentage: Double) -> ZoneInfo {
        if percentage >= 80 {
            return ZoneInfo(
                color: Color.greenZone,
                status: "stable",
                guidance: "You are in the Green Zone. Continue your regular plan."
            )
        } else if percentage >= 50 {
            return ZoneInfo(
                color: Color.yellowZone,
                status: "warning",
                guidance: "You are in the Yellow Zone. Use your reliever inhaler."
            )
        } else {
            return ZoneInfo(
                color: Color.redZone,
                status: "emergency",
                guidance: "Severe risk! Follow emergency plan and seek help."
            )
        }
    }
    
    private func loadData() {
        Task {
            do {
                async let profileReq = APIService.shared.getMyProfile()
                async let recordsReq = APIService.shared.getMyPefrRecords()
                async let symptomsReq = APIService.shared.getMySymptomRecords()
                async let dismissedReq = APIService.shared.getDismissedSymptomIds()
                async let dismissedPefrReq = APIService.shared.getDismissedPefrIds()
                
                let (profile, records, symptoms, dismissedIds, dismissedPefrIds) = try await (profileReq, recordsReq, symptomsReq, dismissedReq, dismissedPefrReq)
                
                await MainActor.run {
                    self.user = profile
                    self.recentPefrRecords = records
                    self.recentSymptoms = symptoms.sorted(by: { $0.recordedAt > $1.recordedAt })
                    
                    // Merge local and backend dismissed symptom IDs
                    let localIds = UserDefaults.standard.array(forKey: dismissedSymptomKey) as? [Int] ?? []
                    let mergedIds = Set(dismissedIds).union(localIds)
                    self.dismissedSymptomIds = mergedIds
                    UserDefaults.standard.set(Array(mergedIds), forKey: dismissedSymptomKey)
                    
                    // If local has new dismissals not yet on the backend, push them
                    if mergedIds.count > dismissedIds.count {
                        Task {
                            for id in localIds {
                                if !dismissedIds.contains(id) {
                                    await APIService.shared.dismissSymptomId(id: id)
                                }
                            }
                        }
                    }

                    // Merge local and backend dismissed PEFR record IDs
                    let localPefrIds = UserDefaults.standard.array(forKey: dismissedPefrKey) as? [Int] ?? []
                    let mergedPefrIds = Set(dismissedPefrIds).union(localPefrIds)
                    self.dismissedPefrIds = mergedPefrIds
                    UserDefaults.standard.set(Array(mergedPefrIds), forKey: dismissedPefrKey)

                    // Push local PEFR dismissals to backend if not yet stored
                    if mergedPefrIds.count > dismissedPefrIds.count {
                        Task {
                            for id in localPefrIds {
                                if !dismissedPefrIds.contains(id) {
                                    await APIService.shared.dismissPefrId(id: id)
                                }
                            }
                        }
                    }

                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func deleteSymptom(_ symptom: Symptom) {
        // Optimistically remove from UI for instant feedback
        withAnimation {
            dismissedSymptomIds.insert(symptom.id)
            UserDefaults.standard.set(Array(dismissedSymptomIds), forKey: dismissedSymptomKey)
            recentSymptoms.removeAll(where: { $0.id == symptom.id })
        }
        
        // Permanent sync/delete via the backend dummy medication
        Task {
            await APIService.shared.dismissSymptomId(id: symptom.id)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        return DateUtils.formatDisplayDateShort(dateString)
    }
}
