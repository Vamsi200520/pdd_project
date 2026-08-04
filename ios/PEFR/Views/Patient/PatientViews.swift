import SwiftUI

// AboutView and AboutCard are the only remaining views in this file
// Other views have been moved to their own dedicated files

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    Spacer()
                }
                .padding(.top, 20)
                
                Text("PEFR Titration Tracker")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                Text("Version 1.0.0")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                
                AboutCard(
                    title: "What is PEFR?",
                    content: "Peak Expiratory Flow Rate (PEFR) measures how quickly a person can exhale. It helps track asthma control and detect early signs of worsening symptoms."
                )
                
                AboutCard(
                    title: "Green Zone",
                    content: "• PEFR > 80% of baseline\n• Good asthma control\n• Continue regular medication",
                    backgroundColor: Color.zoneGreenLight
                )
                
                AboutCard(
                    title: "Yellow Zone",
                    content: "• PEFR 50% - 80% of baseline\n• Possible asthma worsening\n• Use reliever inhaler\n• Follow action plan",
                    backgroundColor: Color.zoneYellowLight
                )
                
                AboutCard(
                    title: "Red Zone",
                    content: "• PEFR < 50% of baseline\n• Severe asthma risk\n• Take rescue medication immediately\n• Seek emergency help",
                    backgroundColor: Color.zoneRedLight
                )
                
                Text("© 2025 PEFR Titration Tracker")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
            }
            .padding()
        }
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("About")
    }
}

struct AboutCard: View {
    let title: String
    let content: String
    var backgroundColor: Color = Color.fieldBackgroundColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primaryDarkColor)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.black)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(16)
    }
}

#Preview {
    AboutView()
}
