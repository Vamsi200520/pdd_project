import SwiftUI

struct VerifyOtpView: View {
    let email: String
    @State private var otp = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "envelope.badge.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
            
            Text("Verify OTP")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Enter the 6-digit code sent to")
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            Text(email)
                .foregroundColor(.white)
                .fontWeight(.medium)
            
            CustomTextField(label: "Enter 6-digit OTP", text: $otp, keyboardType: .numberPad)
                .padding(.horizontal, 40)
            
            Button(action: handleVerify) {
                if isLoading {
                    ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify")
                    .font(.system(size: 18, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .disabled(isLoading || otp.count != 6)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Verification Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("Login Now") { dismiss() }
        } message: {
            Text("Email verified successfully. Please login.")
        }
    }
    
    private func handleVerify() {
        guard otp.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await APIService.shared.verifySignupOtp(email: email, otp: otp)
                
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
