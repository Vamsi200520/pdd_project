import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToReset = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "lock.rotation")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
            
            Text("Forgot Password?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Enter your email to receive an OTP")
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            CustomTextField(label: "Email", text: $email, keyboardType: .emailAddress)
                .padding(.horizontal, 40)
            
            Button(action: handleSendOtp) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send OTP")
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
            
            Button(action: { dismiss() }) {
                Text("Back to Login")
                    .foregroundColor(.white)
            }
            
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
        .navigationDestination(isPresented: $navigateToReset) {
            ResetPasswordView(email: email)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func handleSendOtp() {
        let sanitizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedEmail.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }
        
        guard isValidEmail(sanitizedEmail) else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await APIService.shared.forgotPassword(email: sanitizedEmail)
                
                await MainActor.run {
                    isLoading = false
                    self.email = sanitizedEmail
                    navigateToReset = true
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
    NavigationStack {
        ForgotPasswordView()
    }
}
