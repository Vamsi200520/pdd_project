import SwiftUI

struct ProfileView: View {
    @Binding var showMenu: Bool
    @State private var user: User? = nil
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var linkedDoctor: User? = nil
    @State private var isLoading = true
    @State private var showEditProfile = false
    @State private var showLinkDoctor = false
    @State private var showSetBaseline = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    private var isDoctor: Bool {
        return user?.role.lowercased() == "doctor"
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section with App Logo
                        VStack(spacing: 16) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 76, height: 76)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 4) {
                                Text(user?.fullName ?? "My Profile")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(isDoctor ? "Doctor Profile" : "Manage your personal information")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 60) // Extra padding for the overlap
                        .frame(maxWidth: .infinity)
                        .background(
                             LinearGradient(gradient: Gradient(colors: [Color.primaryDarkColor, Color.primaryColor]), startPoint: .top, endPoint: .bottom)
                        )
                        
                        VStack(spacing: 24) {
                            // Profile Information Card
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Personal Information")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primaryColor)
                                    .padding(.bottom, 8)
                                
                                if let user = user {
                                    ProfileInfoItem(icon: "person.fill", label: "Full Name", value: user.fullName ?? "")
                                    ProfileInfoItem(icon: "envelope.fill", label: "Email Address", value: user.email)
                                    ProfileInfoItem(icon: "phone.fill", label: "Contact Number", value: user.contactInfo ?? "")
                                    ProfileInfoItem(icon: "location.fill", label: "Address", value: user.address ?? "")
                                    
                                    if !isDoctor {
                                        ProfileInfoItem(icon: "number", label: "Age", value: user.age != nil ? "\(user.age!)" : "")
                                        ProfileInfoItem(icon: "ruler.fill", label: "Height (cm)", value: user.height != nil ? "\(user.height!)" : "")
                                        ProfileInfoItem(icon: "person.2.fill", label: "Gender", value: user.gender ?? "")
                                        
                                        Button(action: { showSetBaseline = true }) {
                                            if let baseline = user.baseline {
                                                ProfileInfoItem(icon: "lungs.fill", label: "Baseline PEFR", value: "\(baseline.baselineValue)")
                                            } else {
                                                ProfileInfoItem(icon: "lungs.fill", label: "Baseline PEFR (Optional)", value: "Not set")
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                         // Doctor specific fields if any
                                    }
                                }
                            }
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.top, -32) // Overlap the header
                            
                            // Emergency Contacts (Patient only)
                            if !isDoctor && !emergencyContacts.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Emergency Contacts")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primaryColor)
                                    
                                    ForEach(emergencyContacts) { contact in
                                        EmergencyContactRow(contact: contact)
                                    }
                                }
                                .padding(24)
                                .background(Color.white)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            
                            // Doctor Link (Patient only)
                            if !isDoctor {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Linked Doctor")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.primaryColor)
                                        Spacer()
                                        if linkedDoctor == nil {
                                            Button(action: { showLinkDoctor = true }) {
                                                Text("Link Now")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                    
                                    if let doctor = linkedDoctor {
                                        LinkedDoctorRow(doctor: doctor, onUnlink: {
                                            handleUnlinkDoctor()
                                        })
                                    } else {
                                        Text("You haven't linked to a doctor yet. Linking allows your doctor to monitor your PEFR records.")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding(24)
                                .background(Color.white)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            
                            // Action Buttons
                            VStack(spacing: 12) {
                                Button(action: { showEditProfile = true }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit Profile")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.primaryColor)
                                    .cornerRadius(16)
                                }
                                
                                // Reports and Logout
                                HStack(spacing: 12) {
                                    if !isDoctor {
                                        NavigationLink(destination: ReportsView()) {
                                            HStack {
                                                Image(systemName: "doc.text")
                                                Text("Reports")
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primaryColor)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryColor, lineWidth: 2))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Button(action: handleLogout) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                            Text("Logout")
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.redZone)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.redZone, lineWidth: 2))
                                    }
                                }
                                
                                Button(action: { showDeleteConfirmation = true }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete Account")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.redZone)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.bottom, 40)
                            .padding(.horizontal, 24)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Deleted hamburger menu button to keep navigation focus on dashboard drawer.
        }
        .onAppear(perform: loadData)
        .sheet(isPresented: $showEditProfile) {
            if let user = user {
                if isDoctor {
                    EditDoctorProfileView(user: user, onSave: { loadData() })
                } else {
                    EditProfileView(user: user, onSave: { loadData() })
                }
            }
        }
        .sheet(isPresented: $showLinkDoctor) {
            LinkDoctorView(onSuccess: { loadData() })
        }
        .sheet(isPresented: $showSetBaseline) {
            SetBaselineView()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { handleDeleteAccount() }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
    
    private func loadData() {
        Task {
            do {
                let profile = try await APIService.shared.getMyProfile()
                let contacts = !isDoctor ? (try? await APIService.shared.getEmergencyContacts()) ?? [] : []
                
                var doctor: User? = nil
                if profile.role.lowercased() == "patient" {
                    doctor = try? await APIService.shared.getLinkedDoctor()
                }
                
                await MainActor.run {
                    self.user = profile
                    self.emergencyContacts = contacts
                    self.linkedDoctor = doctor
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
    
    private func handleUnlinkDoctor() {
        Task {
            do {
                _ = try await APIService.shared.unlinkDoctor()
                await MainActor.run {
                    self.linkedDoctor = nil
                    // Refresh data to be sure
                    loadData()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to unlink: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func handleLogout() {
        SessionManager.shared.clearSession()
    }
    
    private func handleDeleteAccount() {
        Task {
            do {
                _ = try await APIService.shared.deleteMyAccount()
                await MainActor.run { handleLogout() }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct ProfileInfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.primaryColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                // Floating label style
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value.isEmpty ? "-" : value)
                    .font(.system(size: 16))
                    .foregroundColor(.fieldTextColor)
            }
            Spacer()
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryDarkColor)
                Text(contact.contactRelationship ?? "Contact")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: {
                if let url = URL(string: "tel://\(contact.phoneNumber)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.primaryColor)
                    .frame(width: 40, height: 40)
                    .background(Color.primaryColorLight)
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct LinkedDoctorRow: View {
    let doctor: User
    var onUnlink: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dr. \(doctor.fullName ?? doctor.email)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryDarkColor)
                Text(doctor.email)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                if let contact = doctor.contactInfo {
                    Text(contact)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            
            Menu {
                Button(action: onUnlink) {
                    HStack {
                        Image(systemName: "person.badge.minus")
                        Text("Unlink")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct EditProfileView: View {
    let user: User
    let onSave: () -> Void
    @State private var name: String
    @State private var age: String
    @State private var height: String
    @State private var gender: String
    @State private var contactInfo: String
    @State private var address: String
    @State private var baselineValue: String
    @State private var isLoading = false
    @State private var fieldErrors: [String: String] = [:]
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    init(user: User, onSave: @escaping () -> Void) {
        self.user = user
        self.onSave = onSave
        _name = State(initialValue: user.fullName ?? "")
        _age = State(initialValue: user.age != nil ? "\(user.age!)" : "")
        _height = State(initialValue: user.height != nil ? "\(user.height!)" : "")
        _gender = State(initialValue: user.gender ?? "Male")
        _contactInfo = State(initialValue: user.contactInfo ?? "")
        _address = State(initialValue: user.address ?? "")
        _baselineValue = State(initialValue: user.baseline != nil ? "\(user.baseline!.baselineValue)" : "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Edit Profile")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    VStack(spacing: 16) {
                        CustomTextField(label: "Name", text: $name, error: fieldErrors["name"])
                            .onChange(of: name) { newValue in
                                name = String(newValue.prefix(50)).filter { $0.isLetter || $0.isWhitespace }
                                fieldErrors["name"] = nil
                            }
                        
                        CustomTextField(label: "Age", text: $age, keyboardType: .numberPad, error: fieldErrors["age"])
                            .onChange(of: age) { newValue in
                                age = String(newValue.prefix(3)).filter { "0123456789".contains($0) }
                                fieldErrors["age"] = nil
                            }
                        
                        CustomTextField(label: "Height (cm)", text: $height, keyboardType: .numberPad, error: fieldErrors["height"])
                            .onChange(of: height) { newValue in
                                height = String(newValue.prefix(3)).filter { "0123456789".contains($0) }
                                fieldErrors["height"] = nil
                            }
                        
                        // Gender made immutable as per request - removed from edit fields
                        
                        CustomTextField(label: "Contact Number", text: $contactInfo, keyboardType: .phonePad, error: fieldErrors["contact"])
                            .onChange(of: contactInfo) { newValue in
                                contactInfo = String(newValue.prefix(10)).filter { "0123456789".contains($0) }
                                fieldErrors["contact"] = nil
                            }
                        
                        CustomTextField(label: "Address", text: $address, isMultiline: true, error: fieldErrors["address"])
                            .onChange(of: address) { newValue in
                                if newValue.count > 150 { address = String(newValue.prefix(150)) }
                                fieldErrors["address"] = nil
                            }
                        
                        CustomTextField(label: "Baseline PEFR (L/min)", text: $baselineValue, keyboardType: .numberPad, error: fieldErrors["baseline"])
                            .onChange(of: baselineValue) { newValue in
                                let filtered = String(newValue.prefix(3)).filter { "0123456789".contains($0) }
                                fieldErrors["baseline"] = nil
                                baselineValue = filtered
                            }
                        
                        Button(action: handleSave) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("SAVE CHANGES")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.top, 8)
                        .disabled(isLoading || name.isEmpty)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.primaryColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Save Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleSave() {
        fieldErrors = [:]
        var hasError = false
        
        if name.isEmpty {
            fieldErrors["name"] = "Name cannot be empty"
            hasError = true
        } else {
            let nameRegex = "^[a-zA-Z\\s]+$"
            let namePredicate = NSPredicate(format:"SELF MATCHES %@", nameRegex)
            if !namePredicate.evaluate(with: name) {
                fieldErrors["name"] = "Characters only"
                hasError = true
            }
        }
        
        let ageInt = Int(age)
        let heightInt = Int(height)
        let baselineInt = Int(baselineValue)
        
        if age.isEmpty {
            fieldErrors["age"] = "Required"
            hasError = true
        } else if let val = ageInt, (val <= 0 || val >= 120) {
            fieldErrors["age"] = "Valid age (1-119)"
            hasError = true
        }
        
        if height.isEmpty {
            fieldErrors["height"] = "Required"
            hasError = true
        } else if let val = heightInt, (val <= 30 || val >= 300) {
            fieldErrors["height"] = "Valid height (30-300)"
            hasError = true
        }
        
        if contactInfo.isEmpty {
            fieldErrors["contact"] = "Required"
            hasError = true
        } else if contactInfo.count != 10 {
            fieldErrors["contact"] = "Must be 10 digits"
            hasError = true
        } else if !["6", "7", "8", "9"].contains(contactInfo.prefix(1)) {
            fieldErrors["contact"] = "Invalid India number (6-9 start)"
            hasError = true
        }
        
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors["address"] = "Required"
            hasError = true
        }
        
        if let bVal = baselineInt {
            if bVal < 0 || bVal > 900 {
                fieldErrors["baseline"] = "Range 0-900"
                hasError = true
            }
        }
        
        guard !hasError else { return }
        
        isLoading = true
        Task {
            do {
                // 1. Update Profile
                let request = ProfileUpdateRequest(
                    fullName: name,
                    age: ageInt,
                    height: heightInt,
                    gender: gender.isEmpty ? nil : gender,
                    contactInfo: contactInfo.isEmpty ? nil : contactInfo,
                    address: address.isEmpty ? nil : address
                )
                _ = try await APIService.shared.updateMyProfile(request: request, userEmail: user.email, userRole: user.role)
                
                // 2. Update Baseline if changed
                if let bVal = baselineInt {
                    _ = try await APIService.shared.setBaseline(baselineValue: bVal)
                }
                
                await MainActor.run {
                    isLoading = false
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct EditDoctorProfileView: View {
    let user: User
    let onSave: () -> Void
    @State private var name: String
    @State private var contactInfo: String
    @State private var address: String
    @State private var isLoading = false
    @State private var fieldErrors: [String: String] = [:]
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss
    
    init(user: User, onSave: @escaping () -> Void) {
        self.user = user
        self.onSave = onSave
        _name = State(initialValue: user.fullName ?? "")
        _contactInfo = State(initialValue: user.contactInfo ?? "")
        _address = State(initialValue: user.address ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Edit Profile")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    VStack(spacing: 16) {
                        CustomTextField(label: "Name", text: $name, error: fieldErrors["name"])
                            .onChange(of: name) { newValue in
                                name = String(newValue.prefix(50)).filter { $0.isLetter || $0.isWhitespace }
                                fieldErrors["name"] = nil
                            }
                        
                        CustomTextField(label: "Contact Number", text: $contactInfo, keyboardType: .phonePad, error: fieldErrors["contact"])
                            .onChange(of: contactInfo) { newValue in
                                contactInfo = String(newValue.prefix(10)).filter { "0123456789".contains($0) }
                                fieldErrors["contact"] = nil
                            }
                        
                        CustomTextField(label: "Address", text: $address, isMultiline: true, error: fieldErrors["address"])
                            .onChange(of: address) { newValue in
                                if newValue.count > 150 { address = String(newValue.prefix(150)) }
                                fieldErrors["address"] = nil
                            }
                        
                        Button(action: handleSave) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("SAVE CHANGES")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.top, 8)
                        .disabled(isLoading || name.isEmpty)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.primaryColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .alert("Save Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleSave() {
        fieldErrors = [:]
        var hasError = false
        
        if name.isEmpty {
            fieldErrors["name"] = "Name cannot be empty"
            hasError = true
        } else {
            let nameRegex = "^[a-zA-Z\\s]+$"
            let namePredicate = NSPredicate(format:"SELF MATCHES %@", nameRegex)
            if !namePredicate.evaluate(with: name) {
                fieldErrors["name"] = "Characters only"
                hasError = true
            }
        }
        
        if contactInfo.isEmpty {
            fieldErrors["contact"] = "Required"
            hasError = true
        } else if contactInfo.count != 10 {
            fieldErrors["contact"] = "Must be 10 digits"
            hasError = true
        } else if !["6", "7", "8", "9"].contains(contactInfo.prefix(1)) {
            fieldErrors["contact"] = "Invalid India number (6-9 start)"
            hasError = true
        }
        
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors["address"] = "Required"
            hasError = true
        }
        
        guard !hasError else { return }
        
        isLoading = true
        Task {
            do {
                let request = ProfileUpdateRequest(
                    fullName: name,
                    age: user.age,
                    height: user.height,
                    gender: user.gender,
                    contactInfo: contactInfo.isEmpty ? nil : contactInfo,
                    address: address.isEmpty ? nil : address
                )
                _ = try await APIService.shared.updateMyProfile(request: request, userEmail: user.email, userRole: user.role)
                await MainActor.run {
                    isLoading = false
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
