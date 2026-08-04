import SwiftUI

struct DoctorDashboardView: View {
    @State private var patients: [User] = []
    @State private var searchText = ""
    @State private var selectedZone = "All"
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    
    let zones = ["All", "Green", "Yellow", "Red"]
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                VStack(spacing: 0) {
                    // Header (Logo + Title + Profile)
                    HStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        
                        Text("Doctor Dashboard")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        NavigationLink(destination: DoctorProfileView()) {
                            Image(systemName: "person.fill")
                                .padding(8)
                                .background(Color.fieldBackgroundColor)
                                .foregroundColor(.primaryColor)
                                .clipShape(Circle())
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.primaryColor)
                    
                    // Search and filter
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                            TextField("", text: $searchText)
                                .foregroundColor(.white)
                                .placeholder(when: searchText.isEmpty) {
                                    Text("Search patients...").foregroundColor(.white.opacity(0.7))
                                }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        
                        Picker("Zone", selection: $selectedZone) {
                            ForEach(zones, id: \.self) { zone in
                                Text(zone).tag(zone)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 4)
                    }
                    .padding()
                    .background(Color.primaryColor)
                    
                    // Patient List
                    if filteredPatients.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.2.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No Patients Found")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(filteredPatients) { patient in
                                    PatientCard(patient: patient, onDelete: {
                                        deletePatient(patient.id)
                                    }, onPrescribe: {
                                        loadPatients()
                                    })
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear(perform: loadPatients)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var filteredPatients: [User] {
        var filtered = patients
        
        if !searchText.isEmpty {
            filtered = filtered.filter { patient in
                (patient.fullName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                patient.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedZone != "All" {
            filtered = filtered.filter { patient in
                patient.latestPefrRecord?.zone.lowercased() == selectedZone.lowercased()
            }
        }
        
        return filtered
    }
    
    private func loadPatients() {
        Task {
            do {
                let zone = selectedZone == "All" ? nil : selectedZone
                let patientList = try await APIService.shared.getDoctorPatients(zone: zone)
                
                await MainActor.run {
                    self.patients = patientList
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
    
    private func deletePatient(_ patientId: Int) {
        Task {
            do {
                try await APIService.shared.deleteLinkedPatient(patientId: patientId)
                loadPatients()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete patient: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// Info Row for Patient Card
struct InfoRow: View {
    let icon: String
    let text: String
    var iconColor: Color = Color.gray
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(iconColor)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#4A4A4A"))
        }
    }
}
struct PatientCard: View {
    let patient: User
    var onDelete: () -> Void
    var onPrescribe: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var dismissedSymptomIds: Set<Int> = []
    
    private var symptomKey: String {
        "doctor_dismissed_symptoms_\(patient.id)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // HEADER
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(patient.fullName ?? "Patient")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primaryColor)
                    }
                    
                    Spacer()
                    
                    if let latestPefr = patient.latestPefrRecord {
                        NavigationLink(destination: GraphView(showMenu: .constant(false), patientId: patient.id, patientName: patient.fullName, preloadedPefrRecord: patient.latestPefrRecord, preloadedSymptom: patient.latestSymptom)) {
                            Text("Zone: \(latestPefr.zone)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(getZoneColor(latestPefr.zone))
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.redZone)
                            .padding(8)
                            .background(Color.redZone.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 16)
                
                NavigationLink(destination: PatientDetailsView(patient: patient)) {
                    // DETAILS SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(icon: "person.text.rectangle", text: "ID: \(patient.id)")
                        InfoRow(icon: "envelope.fill", text: patient.email)
                        if let contact = patient.contactInfo {
                            InfoRow(icon: "phone.fill", text: contact)
                        }
                        if let latestPefr = patient.latestPefrRecord {
                            InfoRow(icon: "lungs.fill", text: "PEFR: \(latestPefr.pefrValue) L/min")
                        }
                        if let latestSymptom = patient.latestSymptom, !dismissedSymptomIds.contains(latestSymptom.id) {
                            HStack {
                                InfoRow(icon: "exclamationmark.triangle.fill", text: "Severity: \(latestSymptom.severity ?? "Not Specified")", iconColor: .redZone)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        dismissedSymptomIds.insert(latestSymptom.id)
                                        UserDefaults.standard.set(Array(dismissedSymptomIds), forKey: symptomKey)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray.opacity(0.3))
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        Text(getStatus(patient))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.yellowZone)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // ACTION BUTTONS
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    NavigationLink(destination: PrescribeMedicationView(patientId: patient.id, patientName: patient.fullName ?? "Patient", onSave: { onPrescribe() })) {
                        Text("Prescribe")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryColor, lineWidth: 1))
                    }
                    
                    NavigationLink(destination: GraphView(showMenu: .constant(false), patientId: patient.id, patientName: patient.fullName, preloadedPefrRecord: patient.latestPefrRecord, preloadedSymptom: patient.latestSymptom)) {
                        Text("History")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryColor, lineWidth: 1))
                    }
                }
            }
            .padding(.top, 18)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
        )
        .onAppear {
            if let saved = UserDefaults.standard.array(forKey: symptomKey) as? [Int] {
                self.dismissedSymptomIds = Set(saved)
            }
        }
        .alert("Delete Patient", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Do you want to delete \(patient.fullName ?? "this patient")?\n\nThis will unlink the patient from you.")
        }
    }
    
    private func getZoneColor(_ zone: String) -> Color {
        switch zone.lowercased() {
        case "green": return Color.greenZone
        case "yellow": return Color.yellowZone
        case "red": return Color.redZone
        default: return Color.gray
        }
    }
    
    private func getStatus(_ patient: User) -> String {
        let zone = patient.latestPefrRecord?.zone ?? patient.latestSymptom?.severity ?? ""
        if zone.lowercased() == "red" {
            return "Status: Critical Attention Needed"
        } else if zone.lowercased() == "yellow" {
            return "Status: Monitoring Required"
        }
        return "Status: Stable"
    }
}

// Repurposing PatientDetailsView as we now have buttons on the card
struct PatientDetailsView: View {
    let patient: User
    @State private var pefrRecords: [PEFRRecord] = []
    @State private var medications: [Medication] = []
    @State private var isLoading = true
    @State private var showPrescribe = false
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Patient Header
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(patient.fullName?.prefix(1).uppercased() ?? "P")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(patient.fullName ?? "Patient")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(patient.email)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 20)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: { showPrescribe = true }) {
                                Label("Prescribe", systemImage: "pills.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.accentColor)
                                    .cornerRadius(12)
                            }
                            
                            NavigationLink(destination: GraphView(showMenu: .constant(false), patientId: patient.id, patientName: patient.fullName, preloadedPefrRecord: patient.latestPefrRecord, preloadedSymptom: patient.latestSymptom)) {
                                Label("View Graph", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.accentColor)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Current Medications
                        if !medications.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Current Medications")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                ForEach(medications) { med in
                                    MedicationSummaryRow(medication: med)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("Patient Details")
        .onAppear(perform: loadData)
        .sheet(isPresented: $showPrescribe) {
            PrescribeMedicationView(patientId: patient.id, patientName: patient.fullName ?? "Patient", onSave: { loadData() })
        }
    }
    
    private func loadData() {
        Task {
            do {
                async let pefr = APIService.shared.getPatientPefrRecords(patientId: patient.id)
                async let meds = APIService.shared.getPatientMedications(patientId: patient.id)
                let (pefrData, medsData) = try await (pefr, meds)
                await MainActor.run {
                    self.pefrRecords = pefrData
                    self.medications = medsData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}

struct MedicationSummaryRow: View {
    let medication: Medication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(medication.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            if let dose = medication.dose {
                Text(dose)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.bgColor.opacity(0.5))
        .cornerRadius(8)
    }
}

struct PrescribeMedicationView: View {
    let patientId: Int
    var patientName: String = "Patient"
    let onSave: () -> Void
    @State private var name = ""
    @State private var dose = ""
    @State private var description = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Patient Info
                    Text(patientName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 28)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medication Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("", text: $name)
                                .textFieldStyle(PrescriptionTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dosage")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("", text: $dose)
                                .textFieldStyle(PrescriptionTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detailed Description (optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(16)
                                .foregroundColor(.black)
                            
                            HStack {
                                Spacer()
                                Text("\(description.count)/150 characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Button(action: handlePrescribe) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("PRESCRIBE")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .padding(.top, 10)
                        .disabled(isLoading || name.isEmpty)
                    }
                    .padding(.horizontal, 28)
                }
            }
            .background(Color.primaryColor.ignoresSafeArea())
            .navigationTitle("Prescribe")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
    
    private func handlePrescribe() {
        isLoading = true
        Task {
            do {
                let request = MedicationCreate(
                    name: name,
                    dose: dose.isEmpty ? nil : dose,
                    schedule: nil,
                    description: description.isEmpty ? nil : description,
                    prescribedBy: nil
                )
                _ = try await APIService.shared.prescribeMedication(patientId: patientId, request: request)
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }
}

struct PrescriptionTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .foregroundColor(.black)
    }
}

struct DoctorProfileView: View {
    var body: some View {
        ProfileView(showMenu: .constant(false))
    }
}

struct PrescriptionHistoryView: View {
    let patientId: Int
    @State private var medications: [MedicationWithHistory] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if medications.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No Prescription History")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(medications) { item in
                            PrescriptionHistoryCard(medication: item)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("History")
        .onAppear(perform: loadData)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadData() {
        Task {
            do {
                let history = try await APIService.shared.getMedicationHistory(patientId: patientId)
                await MainActor.run {
                    self.medications = history
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

struct PrescriptionHistoryCard: View {
    let medication: MedicationWithHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medication.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text((medication.takenStatus ?? "Not Updated").capitalized)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getStatusColor(medication.takenStatus ?? "Not Updated"))
                    .cornerRadius(4)
            }
            
            if let dose = medication.dose {
                Text("Dose: \(dose)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if let schedule = medication.schedule {
                Text("Schedule: \(schedule)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack {
                if let startDate = medication.startDate {
                    Text("Start: \(DateUtils.formatDisplayDate(startDate, format: "MMM d, yyyy"))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // If there's status history, show the latest update
                if let lastUpdate = medication.statusHistory?.first {
                    Text("Status: \(DateUtils.formatDisplayDate(lastUpdate.changedAt, format: "MMM d, HH:mm"))")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.bgColor)
        .cornerRadius(12)
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "taken", "active": return .greenZone
        case "discontinued", "missed": return .redZone
        case "completed": return .blue
        default: return .gray
        }
    }
}


#Preview {
    NavigationStack {
        DoctorDashboardView()
    }
}
