import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    var selectedItem: (Int) -> Void
    var onAbout: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isShowing {
                // Background Dim
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeMenu()
                    }
                
                // Menu Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .center, spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(20)
                            .padding(.top, 15)
                        
                        VStack(spacing: 4) {
                            Text("PEFR Titration Tracker")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Personal Respiratory Assistant")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                    .background(Color.primaryColor)
                    
                    // Menu Items
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            MenuItem(icon: "house.fill", title: "Home") {
                                selectedItem(0)
                                closeMenu()
                            }
                            MenuItem(icon: "chart.line.uptrend.xyaxis", title: "Graph") {
                                selectedItem(1)
                                closeMenu()
                            }
                            MenuItem(icon: "sparkles", title: "AI Advisor") {
                                selectedItem(2)
                                closeMenu()
                            }
                            MenuItem(icon: "bell.fill", title: "Notifications") {
                                selectedItem(3)
                                closeMenu()
                            }
                            MenuItem(icon: "pills.fill", title: "Prescription") {
                                selectedItem(5)
                                closeMenu()
                            }
                            MenuItem(icon: "person.fill", title: "Profile") {
                                selectedItem(4)
                                closeMenu()
                            }
                            
                            Divider().padding(.vertical, 10)
                            
                            MenuItem(icon: "info.circle.fill", title: "About") {
                                onAbout()
                                closeMenu()
                            }
                        }
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .frame(width: 280)
                .background(Color.white)
                .transition(.move(edge: .leading))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 0)
            }
        }
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = false
        }
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(.primaryTextColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true), selectedItem: { _ in }, onAbout: {})
}
