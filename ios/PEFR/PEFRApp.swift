//
//  PEFRApp.swift
//  PEFR
//
//  Created by SAIL on 09/02/26.
//

import SwiftUI

@main
struct PEFRApp: App {
    @StateObject private var session = SessionManager.shared
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(isActive: $showSplash)
            } else if session.isAuthenticated {
                if session.fetchUserRole()?.lowercased() == "doctor" {
                    DoctorRootView()
                } else {
                    PatientRootView()
                }
            } else {
                LoginView()
            }
        }
    }
}
