import SwiftUI

struct SetBaselineView: View {
    @State private var baselineValue = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "lungs")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                
                Text("Set Baseline PEFR")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your personal best Peak Expiratory Flow Rate is used to calculate your asthma zones.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                CustomTextField(label: "Baseline Value (L/min)", text: $baselineValue, keyboardType: .numberPad)
                    .padding(.horizontal, 40)
                    .onChange(of: baselineValue) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if let value = Int(filtered), value > 900 {
                            errorMessage = "This is not the correct PEFR value. Please enter a value between 0 and 900."
                            showError = true
                        }
                        baselineValue = filtered
                    }
                
                Button(action: handleSave) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Baseline")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(20)
                .padding(.horizontal, 40)
                .disabled(isLoading || baselineValue.isEmpty)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Baseline PEFR updated successfully")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleSave() {
        guard let value = Int(baselineValue), value >= 0 && value <= 900 else {
            errorMessage = "This is not the correct PEFR value. Please enter a value between 0 and 900."
            showError = true
            return
        }
        
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.setBaseline(baselineValue: value)
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

#Preview {
    SetBaselineView()
}
