import SwiftUI
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    private let defaults = UserDefaults.standard
    
    private let authTokenKey = "auth_token"
    private let userRoleKey = "user_role"
    private let userEmailKey = "user_email"
    private let profileImageUriKey = "profile_image_uri"
    
    @Published var isAuthenticated: Bool = false
    
    private init() {
        self.isAuthenticated = defaults.string(forKey: authTokenKey) != nil
    }
    
    // MARK: - Auth Token
    @MainActor
    func saveAuthToken(_ token: String) {
        defaults.set(token, forKey: authTokenKey)
        isAuthenticated = true
    }
    
    func fetchAuthToken() -> String? {
        return defaults.string(forKey: authTokenKey)
    }
    
    @MainActor
    func clearAuthToken() {
        defaults.removeObject(forKey: authTokenKey)
        isAuthenticated = false
    }
    
    // MARK: - User Role
    func saveUserRole(_ role: String) {
        defaults.set(role, forKey: userRoleKey)
    }
    
    func fetchUserRole() -> String? {
        return defaults.string(forKey: userRoleKey)
    }
    
    // MARK: - User Email
    func saveUserEmail(_ email: String) {
        defaults.set(email, forKey: userEmailKey)
    }
    
    func fetchUserEmail() -> String? {
        return defaults.string(forKey: userEmailKey)
    }
    
    // MARK: - Profile Image URI
    func saveProfileImageUri(_ uri: String) {
        defaults.set(uri, forKey: profileImageUriKey)
    }
    
    func fetchProfileImageUri() -> String? {
        return defaults.string(forKey: profileImageUriKey)
    }
    
    // MARK: - Check if logged in
    func isLoggedIn() -> Bool {
        return isAuthenticated
    }
    
    // MARK: - Clear all session data
    @MainActor
    func clearSession() {
        defaults.removeObject(forKey: authTokenKey)
        defaults.removeObject(forKey: userRoleKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: profileImageUriKey)
        isAuthenticated = false
    }
}
