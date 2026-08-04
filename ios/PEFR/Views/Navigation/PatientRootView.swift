import SwiftUI

struct PatientRootView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    @State private var showAbout = false
    @State private var showPrescription = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeDashboardView(showMenu: $showMenu)
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                NavigationStack {
                    GraphView(showMenu: $showMenu, patientId: nil)
                }
                .tabItem {
                    Label("Graph", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
                
                NavigationStack {
                    AIAgentView(showMenu: $showMenu)
                }
                .tabItem {
                    Label {
                        Text("AI Advisor")
                    } icon: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#FF00CC"), Color(hex: "#3366FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                Color.gray.opacity(0.3)
                            )
                    }
                }
                .tag(2)
                
                NavigationStack {
                    NotificationsView(showMenu: $showMenu)
                }
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .tag(3)
                
                NavigationStack {
                    ProfileView(showMenu: $showMenu)
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
            }
            .accentColor(.accentColor)
            
            SideMenuView(isShowing: $showMenu, selectedItem: { index in
                if index == 5 {
                    showPrescription = true
                } else {
                    selectedTab = index
                }
            }, onAbout: {
                showAbout = true
            })
        }
        .fullScreenCover(isPresented: $showPrescription) {
            NavigationStack {
                TreatmentPlanView(showMenu: .constant(false))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { showPrescription = false }
                                .foregroundColor(.white)
                        }
                    }
            }
        }
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                AboutView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showAbout = false }
                        }
                    }
            }
        }
    }
}

#Preview {
    PatientRootView()
}
