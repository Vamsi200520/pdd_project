import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole = "Patient"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToSignup = false
    @State private var navigateToForgotPassword = false
    @State private var isPasswordVisible = false
    
    // Focus states to explicitly control keyboard focus
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }

    let roles = ["Patient", "Doctor"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main background
                Color.primaryColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo Section
                        VStack(spacing: 15) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .padding(.top, 40)
                                .shadow(radius: 5)
                            
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Input Card
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Email Address")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                TextField("email@example.com", text: $email)
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: email) { newValue in
                                        email = newValue.lowercased()
                                    }
                                    .submitLabel(.next)
                                    .padding(16)
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .email ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
                                    )
                                    .onSubmit { focusedField = .password }
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    if isPasswordVisible {
                                        TextField("********", text: $password)
                                            .focused($focusedField, equals: .password)
                                    } else {
                                        SecureField("********", text: $password)
                                            .focused($focusedField, equals: .password)
                                    }
                                    
                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .password ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1.5)
                                )
                                .onSubmit(handleLogin)
                            }
                            
                            // Role Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Identity")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                Picker("Role", selection: $selectedRole) {
                                    ForEach(roles, id: \.self) { role in
                                        Text(role).tag(role)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.top, 5)
                            }
                        }
                        .padding(25)
                        .background(Color.white.opacity(0.98))
                        .cornerRadius(24)
                        .padding(.horizontal, 24)
                        
                        // Buttons
                        VStack(spacing: 16) {
                            Button(action: handleLogin) {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("LOGIN")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.buttonColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            
                            Button(action: { navigateToForgotPassword = true }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { navigateToSignup = true }) {
                                HStack {
                                    Text("Don't have an account?")
                                    Text("Sign Up")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.accentColor)
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToSignup) {
                SignupView()
            }
            .navigationDestination(isPresented: $navigateToForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Login Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onTapGesture {
            focusedField = nil // Dismiss keyboard when tapping outside
        }
    }
    
    private func handleLogin() {
        let sanitizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitizedEmail.isEmpty || password.isEmpty {
            errorMessage = "Please enter both email and password"
            showError = true
            return
        }
        
        isLoading = true
        Task {
            do {
                let response = try await APIService.shared.login(email: sanitizedEmail, password: password)
                
                await MainActor.run {
                    let returnedRole = response.userRole.lowercased()
                    let selected = selectedRole.lowercased()
                    
                    // Standard role matching
                    let isMatch = selected == returnedRole
                    
                    if isMatch {
                        SessionManager.shared.saveAuthToken(response.accessToken)
                        SessionManager.shared.saveUserRole(response.userRole)
                        SessionManager.shared.saveUserEmail(sanitizedEmail)
                        isLoading = false
                    } else {
                        errorMessage = "This account is registered as a \(returnedRole). Please select the correct identity."
                        showError = true
                        isLoading = false
                    }
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
