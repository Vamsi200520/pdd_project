import SwiftUI

struct HistoryListView: View {
    var patientId: Int? = nil
    @State private var records: [PEFRRecord] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss

    @State private var dismissedPefrIds: Set<Int> = []
    private let dismissedPefrKey = "patient_dismissed_pefr"
    @State private var baseline: Int = 450

    private var filteredRecords: [PEFRRecord] {
        if isDoctorMode { return records }
        return records.filter { !dismissedPefrIds.contains($0.id) }
    }

    private var isDoctorMode: Bool { patientId != nil }

    var body: some View {
        ZStack {
            Color.primaryColor.ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if filteredRecords.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white.opacity(0.5))
                        Text("No records found")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                } else {
                    recordsList
                }
            }
        }
        .navigationTitle("PEFR History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarItems(trailing: trailingButton)
        .onAppear(perform: loadData)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    private var recordsList: some View {
        List {
            if isDoctorMode {
                // Doctor: read-only, no swipe-to-delete
                ForEach(filteredRecords) { record in
                    HistoryRow(record: record, baseline: baseline)
                        .listRowBackground(Color.white.opacity(0.05))
                }
            } else {
                // Patient: swipe-to-delete enabled (calls backend)
                ForEach(filteredRecords) { record in
                    HistoryRow(record: record, baseline: baseline)
                        .listRowBackground(Color.white.opacity(0.05))
                }
                .onDelete(perform: deleteRecord)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var trailingButton: some View {
        // Only show Edit button for patient (not doctor)
        if !isDoctorMode {
            EditButton()
                .foregroundColor(.white)
        }
    }

    private func loadData() {
        Task {
            do {
                // Fetch Profile for Baseline
                if !isDoctorMode {
                    if let profile = try? await APIService.shared.getMyProfile() {
                        await MainActor.run {
                            self.baseline = profile.baseline?.baselineValue ?? 450
                        }
                    }
                } else if let pid = patientId {
                    if let profile = try? await APIService.shared.getPatientProfile(patientId: pid) {
                        await MainActor.run {
                            self.baseline = profile.baseline?.baselineValue ?? 450
                        }
                    }
                }

                // Fetch dismissed PEFR record IDs from backend metadata
                let dismissedIds = isDoctorMode ? [] : await APIService.shared.getDismissedPefrIds()

                let pefrRecords: [PEFRRecord]
                if let pid = patientId {
                    pefrRecords = try await APIService.shared.getPatientPefrRecords(patientId: pid)
                } else {
                    pefrRecords = try await APIService.shared.getMyPefrRecords()
                }

                await MainActor.run {
                    self.records = pefrRecords.sorted(by: {
                        (DateUtils.parseRobustDate($0.recordedAt) ?? Date()) >
                        (DateUtils.parseRobustDate($1.recordedAt) ?? Date())
                    })
                    
                    if !isDoctorMode {
                        let localIds = UserDefaults.standard.array(forKey: dismissedPefrKey) as? [Int] ?? []
                        let mergedIds = Set(dismissedIds).union(localIds)
                        self.dismissedPefrIds = mergedIds
                        UserDefaults.standard.set(Array(mergedIds), forKey: dismissedPefrKey)
                        
                        // Push local dismissals to backend if not yet stored
                        if mergedIds.count > dismissedIds.count {
                            Task {
                                for id in localIds {
                                    if !dismissedIds.contains(id) {
                                        await APIService.shared.dismissPefrId(id: id)
                                    }
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

    /// Deletes the selected records from the BACKEND via the API.
    /// This makes the deletion permanent and visible to the linked doctor
    /// the next time they refresh / open the patient's data.
    private func deleteRecord(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredRecords[$0] }

        // Optimistically remove from local list for instant UI feedback
        withAnimation {
            for record in toDelete {
                records.removeAll(where: { $0.id == record.id })
                dismissedPefrIds.insert(record.id)
            }
            UserDefaults.standard.set(Array(dismissedPefrIds), forKey: dismissedPefrKey)
        }

        // Notify all graph/home views to reload immediately so the graph
        // no longer shows the deleted records
        NotificationCenter.default.post(name: Foundation.Notification.Name("pefrRecordsDidChange"), object: nil)

        // Best-effort backend delete and persistent dismissal sync
        Task {
            for record in toDelete {
                try? await APIService.shared.deletePEFRRecord(id: record.id)
                await APIService.shared.dismissPefrId(id: record.id)
            }
        }
    }
}

struct HistoryRow: View {
    let record: PEFRRecord
    let baseline: Int

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(getZoneColor(value: record.pefrValue, baseline: baseline))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.pefrValue) L/min")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(DateUtils.formatDisplayDateShort(record.recordedAt))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 8)
    }

    private func getZoneColor(value: Int, baseline: Int) -> Color {
        let percentage = baseline > 0 ? (Double(value) / Double(baseline) * 100) : 0
        if percentage >= 80 { return .greenZone }
        if percentage >= 50 { return .yellowZone }
        return .redZone
    }
}

#Preview {
    NavigationStack {
        HistoryListView()
    }
}
