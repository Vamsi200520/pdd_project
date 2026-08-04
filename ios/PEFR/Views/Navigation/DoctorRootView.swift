import SwiftUI

struct DoctorRootView: View {
    var body: some View {
        NavigationStack {
            DoctorDashboardView()
        }
    }
}

#Preview {
    DoctorRootView()
}