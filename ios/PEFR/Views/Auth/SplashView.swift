import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    
    var body: some View {
        ZStack {
            Color.primaryColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                
                Text("PEFR Titration Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Managing Asthma, One Breath at a Time")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    SplashView(isActive: .constant(true))
}
