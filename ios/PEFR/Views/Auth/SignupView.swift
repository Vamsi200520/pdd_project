import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var gender = "Male"
    @State private var contactNumber = ""
    @State private var address = ""
    @State private var selectedRole = "Patient"
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var navigateToVerifyOtp = false
    @State private var isPasswordVisible = false
    @State private var fieldErrors: [Field: String] = [:]
    @Environment(\.dismiss) var dismiss
    
    // Explicit focus management for keyboard stability
    @FocusState private var focusedField: Field?
    enum Field {
        case name, email, password, age, height, contact, address
    }
    
    let roles = ["Patient", "Doctor"]
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Using direct TextFields for maximum keyboard stability
                    fieldStack(label: "Full Name", text: $name, field: .name)
                    fieldStack(label: "Email", text: $email, field: .email, type: .emailAddress)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
                        HStack {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Password", text: $password)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onChange(of: password) { newValue in
                            if newValue.count > 30 {
                                password = String(newValue.prefix(30))
                            }
                            fieldErrors[.password] = nil
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        
                        if let error = fieldErrors[.password] {
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.red.opacity(0.9))
                                .padding(.horizontal, 4)
                        }
                    }
                    
                    HStack(spacing: 15) {
                        fieldStack(label: "Age", text: $age, field: .age, type: .numberPad)
                        fieldStack(label: "Height (cm)", text: $height, field: .height, type: .numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gender").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                        Picker("Gender", selection: $gender) {
                            ForEach(genders, id: \.self) { Text($0) }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    fieldStack(label: "Contact Number", text: $contactNumber, field: .contact, type: .phonePad)
                    fieldStack(label: "Address", text: $address, field: .address)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select Identity").font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                        Picker("Role", selection: $selectedRole) {
                            ForEach(roles, id: \.self) { role in
                                Text(role).tag(role)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 24)
                
                Button(action: handleSignup) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .bold))
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
                
                Button(action: { dismiss() }) {
                    Text("Already have an account? Login")
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.primaryColor.ignoresSafeArea())
        .onTapGesture { focusedField = nil }
        .navigationDestination(isPresented: $navigateToVerifyOtp) {
            VerifyOtpView(email: email)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private func fieldStack(label: String, text: Binding<String>, field: Field, type: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            TextField(label, text: text)
                .focused($focusedField, equals: field)
                .keyboardType(type)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.none)
                .onChange(of: text.wrappedValue) { newValue in
                    var updated = newValue
                    
                    // Enforce strict character limits and types
                    if field == .contact {
                        updated = String(newValue.prefix(10)).filter { $0.isNumber }
                    } else if field == .name {
                        updated = String(newValue.prefix(50)).filter { $0.isLetter || $0.isWhitespace }
                    } else if field == .age || field == .height {
                        updated = String(newValue.prefix(3)).filter { $0.isNumber }
                    } else if field == .address {
                        updated = String(newValue.prefix(150))
                    } else if field == .email {
                        updated = String(newValue.lowercased().prefix(80)).trimmingCharacters(in: .whitespaces)
                    }
                    
                    if updated != newValue {
                        text.wrappedValue = updated
                    }
                    fieldErrors[field] = nil
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(10)
            
            if let error = fieldErrors[field] {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.red.opacity(0.9))
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private func handleSignup() {
        fieldErrors = [:] // Clear previous errors
        let sanitizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var hasError = false
        
        // Basic requirement checks
        if sanitizedEmail.isEmpty {
            fieldErrors[.email] = "Email is required"
            hasError = true
        } else {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: sanitizedEmail) {
                fieldErrors[.email] = "Invalid email address format"
                hasError = true
            }
        }
        
        if password.isEmpty {
            fieldErrors[.password] = "Password is required"
            hasError = true
        } else if password.count < 6 {
            fieldErrors[.password] = "Password must be at least 6 characters"
            hasError = true
        }
        
        if name.isEmpty {
            fieldErrors[.name] = "Full Name is required"
            hasError = true
        } else {
            let nameRegex = "^[a-zA-Z\\s]+$"
            let namePredicate = NSPredicate(format:"SELF MATCHES %@", nameRegex)
            if !namePredicate.evaluate(with: name) {
                fieldErrors[.name] = "Name should only contain characters"
                hasError = true
            }
        }
        
        if let ageInt = Int(age) {
            if ageInt <= 0 || ageInt >= 120 {
                fieldErrors[.age] = "Valid age (1-119)"
                hasError = true
            }
        } else {
            fieldErrors[.age] = "Required"
            hasError = true
        }
        
        if let heightInt = Int(height) {
            if heightInt <= 30 || heightInt >= 300 {
                fieldErrors[.height] = "Valid height (30-300)"
                hasError = true
            }
        } else {
            fieldErrors[.height] = "Required"
            hasError = true
        }
        
        if contactNumber.isEmpty {
            fieldErrors[.contact] = "Required"
            hasError = true
        } else if contactNumber.count != 10 {
            fieldErrors[.contact] = "Must be exactly 10 digits"
            hasError = true
        } else if !["6", "7", "8", "9"].contains(contactNumber.prefix(1)) {
            fieldErrors[.contact] = "Enter valid Indian number (6-9 start)"
            hasError = true
        }
        
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors[.address] = "Address is required"
            hasError = true
        }
        
        guard !hasError else { return }
        
        isLoading = true
        Task {
            do {
                let request = SignupRequest(
                    email: sanitizedEmail,
                    password: password,
                    role: selectedRole,
                    fullName: name,
                    age: Int(age),
                    height: Int(height),
                    gender: gender,
                    contactInfo: contactNumber,
                    address: address
                )
                _ = try await APIService.shared.signupSendOtp(request: request)
                await MainActor.run {
                    isLoading = false
                    navigateToVerifyOtp = true
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
