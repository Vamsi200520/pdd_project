import SwiftUI

struct PEFRInputView: View {
    @State private var pefrValue = ""
    @State private var isLoading = false
    @State private var showResult = false
    @State private var result: PEFRRecordResponse?
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "waveform.path.ecg")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
            
            Text("Record PEFR")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Enter your Peak Expiratory Flow Rate")
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            TextField("", text: $pefrValue)
                .keyboardType(.numberPad)
                .onChange(of: pefrValue) { newValue in
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if let value = Int(filtered), value > 900 {
                        errorMessage = "This is not the correct PEFR value. Please enter a value between 0 and 900."
                        showError = true
                    }
                    pefrValue = filtered
                }
                .placeholder(when: pefrValue.isEmpty) {
                    Text("000")
                        .foregroundColor(.gray.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .multilineTextAlignment(.center)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 40)
            
            Button(action: handleSubmit) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Submit")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .disabled(isLoading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showResult) {
            if let result = result {
                PEFRResultSheet(result: result, onDismiss: {
                    dismiss()
                })
            }
        }
    }
    
    private func handleSubmit() {
        guard let value = Int(pefrValue), value >= 0 && value <= 900 else {
            errorMessage = "This is not the correct PEFR value. Please enter a value between 0 and 900."
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await APIService.shared.recordPEFR(pefrValue: value)
                
                await MainActor.run {
                    self.result = response
                    self.isLoading = false
                    self.showResult = true
                    // Notify all views (graph, history) to reload with the new record
                    NotificationCenter.default.post(name: Foundation.Notification.Name("pefrRecordsDidChange"), object: nil)
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

struct PEFRResultSheet: View {
    let result: PEFRRecordResponse
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(result.zone)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            Text("\(result.record.pefrValue)")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(Int(result.percentage ?? 0))% of baseline")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.9))
            
            Text("Trend: \(result.trend ?? "Stable")")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
            
            Text(result.guidance)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 20)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(getZoneColor(result.zone).ignoresSafeArea())
    }
    
    private func getZoneColor(_ zone: String) -> Color {
        switch zone.lowercased() {
        case "green": return Color.greenZone
        case "yellow": return Color.yellowZone
        case "red": return Color.redZone
        default: return Color.bgColor
        }
    }
}

#Preview {
    NavigationStack {
        PEFRInputView()
    }
}
