import SwiftUI

struct AlertsView: View {
    @State private var alerts: [AlertLog] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if alerts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.shield")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No System Alerts")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Important system announcements and critical alerts will appear here.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(alerts) { alert in
                            AlertRow(alert: alert)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadAlerts)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadAlerts() {
        Task {
            do {
                let list = try await APIService.shared.getAlerts()
                await MainActor.run {
                    self.alerts = list
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
}

struct AlertRow: View {
    let alert: AlertLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.alertType.contains("RED") ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(alert.alertType.contains("RED") ? .red : .yellow)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.alertType.replacingOccurrences(of: "_", with: " "))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(alertMessage(alert.alertType))
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(formatDate(alert.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.bgColor)
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
    
    private func alertMessage(_ type: String) -> String {
        switch type {
        case "PEFR_RED_ZONE": return "Your PEFR is in the critical RED zone. Please follow your emergency action plan immediately."
        case "PEFR_YELLOW_ZONE": return "Your PEFR is in the caution YELLOW zone. Monitor your symptoms closely."
        case "MISSING_MEDICATION": return "You missed your scheduled medication. Adherence is important for control."
        case "CRITICAL_ML_PREDICTION": return "AI analysis indicates a possible worsening of your condition."
        default: return "System notification regarding your health tracking."
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, yyyy HH:mm"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    NavigationStack {
        AlertsView()
    }
}
