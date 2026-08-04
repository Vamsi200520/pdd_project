import SwiftUI

struct ResetPasswordView: View {
    let email: String
    @State private var otp = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Spacer().frame(height: 40)
                
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                
                Text("Reset Password")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Enter OTP and new password")
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    CustomTextField(label: "6-digit OTP", text: $otp, keyboardType: .numberPad)
                    CustomSecureField(label: "New Password", text: $newPassword)
                    CustomSecureField(label: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal, 40)
                
                Button(action: handleReset) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Reset Password")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(20)
                .padding(.horizontal, 40)
                .disabled(isLoading || otp.isEmpty || newPassword.isEmpty)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleReset() {
        guard !otp.isEmpty, !newPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await APIService.shared.resetPassword(
                    email: email,
                    otp: otp,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    dismiss()
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
