import SwiftUI

struct LinkDoctorView: View {
    @State private var doctorEmail = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    var onSuccess: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                Image(systemName: "person.badge.plus.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text("Link to Doctor")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Enter your doctor's email address to start sharing your health data in real-time.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    CustomTextField(label: "Doctor's Email", text: $doctorEmail, keyboardType: .emailAddress)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                
                Button(action: handleLink) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("LINK DOCTOR")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(18)
                .padding(.horizontal, 28)
                .padding(.top, 10)
                .disabled(isLoading || doctorEmail.isEmpty)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryColor.ignoresSafeArea())
            .navigationTitle("Doctor Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { 
                    onSuccess?()
                    dismiss() 
                }
            } message: {
                Text("Successfully linked to the doctor.")
            }
        }
    }
    
    private func handleLink() {
        guard doctorEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            showError = true
            return
        }
        
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.linkDoctor(doctorEmail: doctorEmail)
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
    LinkDoctorView(onSuccess: nil)
}
