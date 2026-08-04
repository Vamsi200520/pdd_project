import SwiftUI

struct SymptomTrackerView: View {
    @State private var wheezeRating: Double = 0
    @State private var coughRating: Double = 0
    @State private var dyspneaRating: Double = 0
    @State private var nightSymptomsRating: Double = 0
    @State private var chestTightnessRating: Double = 0
    @State private var activityLimitationRating: Double = 0
    @State private var rescueInhalerPuffs: String = ""
    
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Track Your Symptoms")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 24) {
                    // Existing Ratings
                    RatingSlider(title: "Wheezing", rating: $wheezeRating)
                    RatingSlider(title: "Cough", rating: $coughRating)
                    RatingSlider(title: "Shortness of Breath", rating: $dyspneaRating)
                    RatingSlider(title: "Night Symptoms", rating: $nightSymptomsRating)
                    
                    // New Ratings
                    RatingSlider(title: "Chest Tightness", rating: $chestTightnessRating)
                    RatingSlider(title: "Activity Limitation", rating: $activityLimitationRating)
                    
                    // Rescue Inhaler Info (valid range: 0–10 puffs/day per NHS guideline)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Rescue Inhaler Usage")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("0–10 puffs")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        TextField("Number of puffs today (0–10)", text: $rescueInhalerPuffs)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)
                            .onChange(of: rescueInhalerPuffs) { newValue in
                                // Allow only digits, clamp to 0–10
                                let digits = newValue.filter { $0.isNumber }
                                if let num = Int(digits) {
                                    rescueInhalerPuffs = num > 10 ? "10" : digits
                                } else {
                                    rescueInhalerPuffs = digits
                                }
                            }

                        // Colour-coded usage hint
                        if let puffs = Int(rescueInhalerPuffs) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(puffs >= 8 ? Color.redZone
                                          : puffs >= 4 ? Color.yellowZone
                                          : Color.greenZone)
                                    .frame(width: 8, height: 8)
                                Text(puffs >= 8
                                     ? "⚠️ High usage — contact your doctor"
                                     : puffs >= 4
                                     ? "Frequent use may indicate poor control"
                                     : "Normal range")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.bgColor.opacity(0.3))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                // Submit Button
                Button(action: handleSubmit) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Record Symptoms")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(20)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .disabled(isLoading)
                
                Spacer().frame(height: 40)
            }
        }
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("Symptom Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Symptoms recorded successfully")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSubmit() {
        isLoading = true
        
        Task {
            do {
                let request = SymptomCreate(
                    wheezeRating: Int(wheezeRating),
                    coughRating: Int(coughRating),
                    dustExposure: false,
                    smokeExposure: false,
                    dyspneaRating: Int(dyspneaRating),
                    nightSymptomsRating: Int(nightSymptomsRating),
                    chestTightnessRating: Int(chestTightnessRating),
                    activityLimitationRating: Int(activityLimitationRating),
                    rescueInhalerPuffs: Int(rescueInhalerPuffs),
                    severity: nil,
                    onsetAt: ISO8601DateFormatter().string(from: Date()),
                    duration: nil,
                    suspectedTrigger: nil
                )
                
                _ = try await APIService.shared.recordSymptom(request: request)
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
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

struct RatingSlider: View {
    let title: String
    @Binding var rating: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(rating))/5")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            
            Slider(value: $rating, in: 0...5, step: 1)
                .tint(.accentColor)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
