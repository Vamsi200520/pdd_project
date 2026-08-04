import SwiftUI

struct TreatmentPlanView: View {
    @Binding var showMenu: Bool
    @State private var medications: [Medication] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showTakeSuccess = false
    @State private var lastTakenName = ""
    @State private var showEditMedication = false
    @State private var showAddMedication = false
    @State private var showMLRecommendation = false
    @State private var selectedMedication: Medication? = nil
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if medications.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "pills")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No Medications")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Add your medications to track adherence")
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text("Contact your doctor to update your treatment plan")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 10)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // ML Insight Button
                        Button(action: { showMLRecommendation = true }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Verify Prescription with AI")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        ForEach(medications) { medication in
                            MedicationCard(medication: medication, onTake: {
                                takeMedication(medication)
                            }, onEdit: {
                                selectedMedication = medication
                                showEditMedication = true
                            }, onDelete: {
                                selectedMedication = medication
                                showDeleteConfirmation = true
                            })
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("Prescription")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadMedications)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showTakeSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(lastTakenName) has been recorded as taken.")
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationView(onSave: { loadMedications() })
        }
        .sheet(isPresented: $showEditMedication) {
            if let med = selectedMedication {
                EditMedicationView(medication: med, onSave: { loadMedications() })
            }
        }
        .sheet(isPresented: $showMLRecommendation) {
            MLRecommendationView()
        }
        .confirmationDialog("Delete Medication", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let med = selectedMedication {
                    deleteMedication(med)
                }
            }
        } message: {
            Text("Are you sure you want to remove '\(selectedMedication?.name ?? "")'? This cannot be undone.")
        }
    }
    
    private func loadMedications() {
        Task {
            do {
                let meds = try await APIService.shared.getMedications()
                await MainActor.run {
                    self.medications = meds
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
    
    private func takeMedication(_ medication: Medication) {
        Task {
            do {
                _ = try await APIService.shared.takeMedication(id: medication.id)
                await MainActor.run {
                    self.lastTakenName = medication.name
                    self.showTakeSuccess = true
                    loadMedications()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func deleteMedication(_ medication: Medication) {
        Task {
            do {
                try await APIService.shared.deleteMedication(id: medication.id)
                loadMedications()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct MedicationCard: View {
    let medication: Medication
    let onTake: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isTaking = false
    @State private var lastTakenTime: String? = nil
    
    private var lastTakenKey: String {
        "last_taken_\(medication.id)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let dose = medication.dose {
                        Text(dose)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Options Menu
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(4)
                }
                
                if let remaining = medication.dosesRemaining {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(remaining)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.accentColor)
                        Text("doses left")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 8) {
                if let schedule = medication.schedule {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                        Text("Schedule: \(schedule)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                if let lastTime = lastTakenTime {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.greenZone)
                        Text("Last taken: \(lastTime)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.greenZone)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 14))
                        Text("No doses recorded today")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            if let description = medication.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    isTaking = true
                    onTake()
                    
                    // Update local timestamp
                    let now = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a, MMM d"
                    let timeString = formatter.string(from: now)
                    
                    UserDefaults.standard.set(timeString, forKey: lastTakenKey)
                    withAnimation {
                        lastTakenTime = timeString
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isTaking = false
                    }
                }) {
                    HStack {
                        if isTaking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "pills.fill")
                        }
                        Text(isTaking ? "Updating..." : "Record Dose Now")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(25)
                }
                .disabled(isTaking)
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            ZStack {
                Color.bgColor
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.05), Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            lastTakenTime = UserDefaults.standard.string(forKey: lastTakenKey)
        }
    }
}

struct EditMedicationView: View {
    let medication: Medication
    let onSave: () -> Void
    @State private var name: String
    @State private var dose: String
    @State private var schedule: String
    @State private var description: String
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    init(medication: Medication, onSave: @escaping () -> Void) {
        self.medication = medication
        self.onSave = onSave
        _name = State(initialValue: medication.name)
        _dose = State(initialValue: medication.dose ?? "")
        _schedule = State(initialValue: medication.schedule ?? "")
        _description = State(initialValue: medication.description ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Medication Name", text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                    TextField("Dose (e.g., 2 puffs)", text: $dose)
                        .textFieldStyle(CustomTextFieldStyle())
                    TextField("Schedule (e.g., Twice daily)", text: $schedule)
                        .textFieldStyle(CustomTextFieldStyle())
                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                .padding()
            }
            .background(Color.primaryColor.ignoresSafeArea())
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { handleSave() }
                        .foregroundColor(.accentColor)
                        .disabled(isLoading || name.isEmpty)
                }
            }
        }
    }
    
    private func handleSave() {
        isLoading = true
        Task {
            do {
                let request = MedicationUpdate(
                    name: name,
                    dose: dose.isEmpty ? nil : dose,
                    schedule: schedule.isEmpty ? nil : schedule,
                    description: description.isEmpty ? nil : description
                )
                _ = try await APIService.shared.updateMedication(id: medication.id, request: request)
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct AddMedicationView: View {
    let onSave: () -> Void
    @State private var name = ""
    @State private var dose = ""
    @State private var schedule = ""
    @State private var description = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Medication Name", text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                    TextField("Dose (e.g., 2 puffs)", text: $dose)
                        .textFieldStyle(CustomTextFieldStyle())
                    TextField("Schedule (e.g., Twice daily)", text: $schedule)
                        .textFieldStyle(CustomTextFieldStyle())
                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                .padding()
            }
            .background(Color.primaryColor.ignoresSafeArea())
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { handleSave() }
                        .foregroundColor(.accentColor)
                        .disabled(isLoading || name.isEmpty)
                }
            }
        }
    }
    
    private func handleSave() {
        isLoading = true
        Task {
            do {
                let request = MedicationCreate(
                    name: name,
                    dose: dose.isEmpty ? nil : dose,
                    schedule: schedule.isEmpty ? nil : schedule,
                    description: description.isEmpty ? nil : description
                )
                _ = try await APIService.shared.addMedication(request: request)
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct MLRecommendationView: View {
    @State private var prediction: MLPrediction?
    @State private var medications: [Medication] = []
    @State private var latestPefr: PEFRRecord?
    @State private var latestSymptom: Symptom?
    @State private var isVerified: Bool = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Analyzing your health data...")
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else if let prediction = prediction {
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: isVerified ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(isVerified ? .greenZone : .yellowZone)
                            
                            let displayGoal = getDisplayTherapyGoal()
                            Text(isVerified ? "Clinical Alignment Found" : "Health Insight Report")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            // 1. Clinical Foundation
                            VStack(alignment: .leading, spacing: 16) {
                                Text("VITAL SIGNS ANALYZED")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentColor)
                                
                                if let pefr = latestPefr {
                                    RecommendationRow(label: "Current PEFR", value: "\(pefr.pefrValue) L/min")
                                    RecommendationRow(label: "Lung Zone", value: pefr.zone)
                                        .foregroundColor(getZoneColor(pefr.zone))
                                }
                                
                                RecommendationRow(label: "Primary Complaint", value: getMainSymptom())
                            }
                            .padding()
                            .background(Color.bgColor.opacity(0.6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // 2. Dynamic Therapeutic Goal
                            VStack(alignment: .leading, spacing: 16) {
                                Text("RECOMMENDED CLINICAL GOAL")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentColor)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(displayGoal)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(displayGoal == prediction.recommendedMedicine ? "Primary Treatment" : "Symptom Target")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    Text("\(Int(prediction.predictedCureProbability * 100))%")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.greenZone)
                                }
                                
                                Text(getRationale(for: displayGoal))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                
                                if displayGoal != prediction.recommendedMedicine {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("Clinical Note: Also consider \(prediction.recommendedMedicine.lowercased()) for long-term control.")
                                            .font(.system(size: 11))
                                    }
                                    .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding()
                            .background(Color.bgColor)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // 3. Symptom-Based Medication Guide
                            VStack(alignment: .leading, spacing: 16) {
                                Text("SYMPTOM-SPECIFIC MEDICATIONS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentColor)
                                
                                let specificMeds = getMedicineBySymptom()
                                if specificMeds.isEmpty {
                                    Text("No additional symptom-specific medications required.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                } else {
                                    ForEach(specificMeds, id: \.name) { med in
                                        HStack {
                                            Image(systemName: "pills.fill")
                                                .foregroundColor(.accentColor)
                                            VStack(alignment: .leading) {
                                                Text(med.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.white)
                                                Text(med.reason)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.bgColor.opacity(0.5))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // 4. Comparison with Doctor's Prescription
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PRESCRIPTION ALIGNMENT")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.accentColor)
                                
                                if medications.isEmpty {
                                    Text("No current medications found. Contact your doctor to update your plan.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                } else {
                                    ForEach(medications) { med in
                                        let specificMeds = getMedicineBySymptom()
                                        let allRecommendations = [prediction.recommendedMedicine] + specificMeds.map { $0.name }
                                        let isMatch = allRecommendations.contains { rec in isMedicationAligned(med, recommended: rec) }
                                        
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(med.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                                if let desc = med.description {
                                                    Text(desc)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.6))
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: isMatch ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(isMatch ? .greenZone : .white.opacity(0.2))
                                        }
                                        .padding(12)
                                        .background(isMatch ? Color.greenZone.opacity(0.1) : Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                        
                                        if let note = getClinicalNote(for: med.name) {
                                            HStack(alignment: .top, spacing: 6) {
                                                Image(systemName: "info.circle.fill")
                                                    .font(.system(size: 10))
                                                Text(note)
                                                    .font(.system(size: 10))
                                                    .lineLimit(2)
                                            }
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.horizontal, 12)
                                            .padding(.top, -8)
                                            .padding(.bottom, 8)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.bgColor.opacity(0.4))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // Final Expert Note
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Clinical Conclusion")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(isVerified ? 
                                     "Your current prescription includes the recommended treatment. Continue as directed by your physician." :
                                     "Review this report with your physician. The AI suggests \(displayGoal.lowercased()) as the priority, which may require a prescription update.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineSpacing(4)
                            }
                            .padding(.horizontal)
                            
                            Spacer().frame(height: 40)
                        }
                        .padding(.top, 20)
                    }
                } else {
                     VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white.opacity(0.5))
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryColor.ignoresSafeArea())
            .navigationTitle("AI Insight Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear(perform: getPrediction)
        }
    }
    
    struct SymptomMedication {
        let name: String
        let reason: String
    }
    
    private func getDisplayTherapyGoal() -> String {
        guard let p = latestPefr, let s = latestSymptom, let pred = prediction else {
            return prediction?.recommendedMedicine ?? "Clinical Monitoring"
        }
        
        // If PEFR is stable (Green) but symptoms are isolated, target the symptom
        if p.zone.lowercased() == "green" {
            if (s.coughRating ?? 0) > 2 && (s.wheezeRating ?? 0) <= 2 {
                return "Cough Suppression"
            }
            if (s.wheezeRating ?? 0) > 2 && (s.coughRating ?? 0) <= 2 {
                return "Bronchodilation"
            }
        }
        
        return pred.recommendedMedicine
    }
    
    private func getRationale(for medicine: String) -> String {
        let med = medicine.lowercased()
        if med.contains("steroid") || med.contains("inflammation") {
            return "Corticosteroids are the foundation of asthma control. They reduce underlying airway inflammation and swelling, which prevents future attacks. They should be used daily as a controller, not just during symptoms."
        } else if med.contains("cough") {
            return "This therapy addresses the hypersensitivity of your cough receptors. While it provides relief from persistent coughing, it must be paired with anti-inflammatory treatment to manage the root cause of your asthma."
        } else if med.contains("broncho") || med.contains("salbutamol") || med.contains("saba") {
            return "Bronchodilators provide rapid relief by relaxing the tight muscles around your airways. They are 'rescue' medications meant for immediate symptom relief but do not treat the underlying inflammation."
        } else {
            return "This clinical goal targets your current respiratory symptoms (PEFR zone and severity) to stabilize your lung function and prevent further deterioration."
        }
    }
    
    private func getClinicalNote(for medName: String) -> String? {
        let name = medName.lowercased()
        if name.contains("dolo") || name.contains("paracetamol") || name.contains("crocin") {
            return "Supportive Care: Used for fever/pain associated with infections (common asthma triggers). Not an asthma treatment."
        }
        if name.contains("levalbuterol") || name.contains("levosalbutamol") || name.contains("albuterol") || name.contains("salbutamol") {
            return "Rescue Only: Use for immediate relief from sudden wheezing or SOB. Do not use for daily control."
        }
        if name.contains("prednisolone") || name.contains("prednisone") {
            return "Systemic Control: Used for severe flare-ups to quickly reduce high levels of inflammation."
        }
        return nil
    }
    
    private func getMedicineBySymptom() -> [SymptomMedication] {
        var meds: [SymptomMedication] = []
        guard let s = latestSymptom else { return [] }
        
        if (s.coughRating ?? 0) > 2 {
            meds.append(SymptomMedication(name: "Cough Suppressant", reason: "For persistent dry cough that disturbs sleep or activity."))
        }
        if (s.wheezeRating ?? 0) > 2 {
            meds.append(SymptomMedication(name: "Reliever Inhaler (SABA)", reason: "To rapidly open narrowed airways and stop wheezing."))
        }
        if (s.dyspneaRating ?? 0) > 2 {
            meds.append(SymptomMedication(name: "Short-acting Bronchodilator", reason: "For immediate relief from breathlessness."))
        }
        if s.dustExposure == true || s.smokeExposure == true {
            meds.append(SymptomMedication(name: "Antihistamine", reason: "If your symptoms are being triggered by an allergic reaction to environment factors."))
        }
        
        return meds
    }
    
    private func getMainSymptom() -> String {
        guard let s = latestSymptom else { return "None" }
        if (s.wheezeRating ?? 0) > 3 { return "Prominent Wheezing" }
        if (s.coughRating ?? 0) > 3 { return "Persistent Cough" }
        if (s.dyspneaRating ?? 0) > 3 { return "Breathlessness" }
        return "Mild Respiratory Strain"
    }
    
    private func getSupportiveAdvice() -> [String] {
        var advice: [String] = []
        guard let s = latestSymptom, let p = latestPefr else { return ["Continue monitoring your peak flow."] }
        
        // PEFR Based Advice
        if p.zone.lowercased() == "yellow" {
            advice.append("Use your reliever inhaler (e.g. Salbutamol) every 4-6 hours.")
        }
        
        // Symptom Based Advice
        if (s.coughRating ?? 0) > 1 {
            advice.append("Hydrate frequently and consider steam inhalation to soothe clinical cough.")
        }
        if (s.wheezeRating ?? 0) > 1 {
            advice.append("Ensure you are using your spacer with your controller inhaler for better drug delivery.")
        }
        if (s.chestTightnessRating ?? 0) > 1 {
            advice.append("Practice deep breathing exercises or pursed-lip breathing to manage tightness.")
        }
        if s.smokeExposure == true {
            advice.append("Exposure to smoke is aggravating your airways. Avoid smoke-filled environments.")
        }
        
        if advice.isEmpty {
            advice.append("Follow your maintenance plan and monitor for any changes in symptom severity.")
        }
        
        return advice
    }
    
    private func getZoneColor(_ zone: String) -> Color {
        switch zone.lowercased() {
        case "green": return .greenZone
        case "yellow": return .yellowZone
        case "red": return .redZone
        default: return .white
        }
    }
    
    private func isMedicationAligned(_ med: Medication, recommended: String) -> Bool {
        let rec = recommended.lowercased()
        let medName = med.name.lowercased()
        
        // Direct name match
        if medName.contains(rec) || rec.contains(medName) { return true }
        
        // Chemical/Category Matching (e.g. Prednisolone matches Oral Steroid)
        if rec.contains("steroid") || rec.contains("inflammation") {
            let steroids = ["prednisolone", "prednisone", "dexa", "hydrocortisone", "medrol", "cortisone"]
            for s in steroids {
                if medName.contains(s) { return true }
            }
        }
        
        if rec.contains("cough") {
            let coughMeds = ["syrup", "mucolyte", "cod", "dextro", "ambroxol", "benadryl", "grilinctus"]
            for c in coughMeds {
                if medName.contains(c) { return true }
            }
        }
        
        if rec.contains("saba") || rec.contains("reliever") || rec.contains("broncho") {
            let bronchos = ["salbutamol", "albuterol", "levalbuterol", "levosalbutamol", "ventolin", "asthalin", "duolin", "ipatropium"]
            for b in bronchos {
                if medName.contains(b) { return true }
            }
        }
        
        // Description match
        let descMatch = med.description?.lowercased().contains(rec) ?? false
        return descMatch
    }
    
    private func getPrediction() {
        Task {
            do {
                async let profile = APIService.shared.getMyProfile()
                async let records = APIService.shared.getMyPefrRecords()
                async let symptoms = APIService.shared.getMySymptomRecords()
                async let currentMeds = APIService.shared.getMedications()
                
                let (user, pefrList, symptomList, medList) = try await (profile, records, symptoms, currentMeds)
                
                guard let latestPefr = pefrList.sorted(by: { $0.recordedAt > $1.recordedAt }).first else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please record your PEFR first."])
                }
                
                let latestSymptom = symptomList.sorted(by: { $0.recordedAt > $1.recordedAt }).first
                
                let input = MLInput(
                    age: user.age,
                    pefrValue: latestPefr.pefrValue,
                    wheezeRating: latestSymptom?.wheezeRating,
                    coughRating: latestSymptom?.coughRating,
                    dustExposure: latestSymptom?.dustExposure,
                    smokeExposure: latestSymptom?.smokeExposure
                )
                
                let result = try await APIService.shared.mlPredict(input: input)
                
                // Check verification against all recommendations (primary + symptom-specific)
                // Temporarily set self.latestSymptom so getMedicineBySymptom works during check
                self.latestSymptom = latestSymptom
                let specificMeds = getMedicineBySymptom()
                let allRecommendations = [result.recommendedMedicine] + specificMeds.map { $0.name }
                
                let matchFound = medList.contains { med in
                    allRecommendations.contains { rec in isMedicationAligned(med, recommended: rec) }
                }
                
                await MainActor.run {
                    self.prediction = result
                    self.medications = medList
                    self.latestPefr = latestPefr
                    self.latestSymptom = latestSymptom
                    self.isVerified = matchFound
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        TreatmentPlanView(showMenu: .constant(false))
    }
}

#Preview("Add Medication") {
    AddMedicationView(onSave: {})
}
