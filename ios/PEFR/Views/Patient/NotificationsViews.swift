import SwiftUI

struct NotificationsView: View {
    @Binding var showMenu: Bool
    // Notification List State
    @State private var notifications: [Notification] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    
    // Reminder Settings State
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var frequency = "Daily" // Daily, Weekly, Monthly
    @State private var targetPefr = ""
    
    // Dismissed Notifications Local Storage
    @State private var dismissedIds: Set<Int> = []
    private let dismissedIdsKey = "patient_dismissed_notifications"
    
    private var filteredNotifications: [Notification] {
        notifications.filter { !dismissedIds.contains($0.id) }
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // - REMINDER CARD -
                        VStack(alignment: .leading, spacing: 16) {
                            
                            // Header Row
                            HStack {
                                Text("Set Reminder")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primaryDarkColor)
                                
                                Spacer()
                                
                                Toggle("", isOn: $reminderEnabled)
                                    .labelsHidden()
                                    .tint(.accentColor)
                            }
                            
                            // Status Text
                            Text(reminderEnabled ? "Reminder Active" : "Reminder Disabled")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.top, -8)
                            
                            // Time Section
                            if reminderEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Time")
                                        .font(.system(size: 16))
                                        .foregroundColor(.fieldTextColor)
                                    
                                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .accentColor(.primaryColor)
                                }
                                .padding(.top, 4)
                                
                                // Frequency Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Frequency")
                                        .font(.system(size: 16))
                                        .foregroundColor(.fieldTextColor)
                                    
                                    HStack(spacing: 20) {
                                        RadioButton(text: "Daily", selected: $frequency)
                                        RadioButton(text: "Weekly", selected: $frequency)
                                        RadioButton(text: "Monthly", selected: $frequency)
                                    }
                                }
                                .padding(.top, 4)
                                
                                // Target PEFR Section
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Target PEFR Value", text: $targetPefr)
                                        .keyboardType(.numberPad)
                                        .onChange(of: targetPefr) { newValue in
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            if let value = Int(filtered) {
                                                if value > 900 {
                                                    targetPefr = "900"
                                                } else {
                                                    targetPefr = filtered
                                                }
                                            } else {
                                                targetPefr = filtered
                                            }
                                        }
                                        .foregroundColor(.fieldTextColor)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .background(Color.fieldBackgroundColor) // Light teal
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(20)
                        
                        // - SAVE BUTTON -
                        if reminderEnabled {
                            VStack(spacing: 8) {
                                Button(action: saveSettings) {
                                    Text("Save Reminder")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color.accentColor)
                                        .cornerRadius(16)
                                }
                                
                                if let nextDate = calculateNextTrigger() {
                                    Text("Next reminder: \(formatNextTrigger(nextDate))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                        
                        // - NOTIFICATIONS HEADER -
                        Text("Notifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white) // White text on primary background
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .padding(.bottom, 12)
                        
                        // - NOTIFICATIONS LIST -
                        VStack(spacing: 12) {
                            if filteredNotifications.isEmpty {
                                Text("No notifications")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 20)
                            } else {
                                ForEach(filteredNotifications) { notification in
                                    NotificationRow(notification: notification, onTap: {
                                        markAsRead(notification)
                                    }, onDelete: {
                                        deleteNotification(notification)
                                    })
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle("Notification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadInitialData()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Settings saved successfully")
        }
    }
    
    private func loadInitialData() {
        // Load dismissed IDs from local storage
        if let saved = UserDefaults.standard.array(forKey: dismissedIdsKey) as? [Int] {
            self.dismissedIds = Set(saved)
        }
        
        // Request notification permission
        LocalNotificationManager.shared.requestPermission()
        
        isLoading = true
        Task {
            do {
                // 1. Get Profile for Baseline
                let profile = try await APIService.shared.getMyProfile()
                // 2. Get Notifications
                let notifs = try await APIService.shared.getNotifications()
                // 3. Get Reminders
                let existingReminders = try await APIService.shared.getReminders()
                
                await MainActor.run {
                    if let baselineValue = profile.baseline?.baselineValue {
                        self.targetPefr = "\(baselineValue)"
                    }
                    
                    self.notifications = notifs.sorted(by: { $0.createdAt > $1.createdAt })
                    
                    if let last = existingReminders.last {
                        self.reminderEnabled = true
                        self.frequency = last.frequency
                        let df = DateFormatter()
                        df.dateFormat = "HH:mm"
                        if let date = df.date(from: last.time) {
                            self.reminderTime = date
                        }
                    } else {
                        self.reminderEnabled = false
                    }
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
    
    private func saveSettings() {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        let timeStr = df.string(from: reminderTime)
        
        // Handle Local Notification Trigger
        if reminderEnabled {
            LocalNotificationManager.shared.scheduleReminder(time: reminderTime, frequency: frequency)
        } else {
            LocalNotificationManager.shared.cancelAll()
        }
        
        isLoading = true
        Task {
            do {
                // Save Reminder to Backend
                let request = ReminderCreate(
                    reminderType: "PEFR",
                    time: timeStr,
                    frequency: frequency
                )
                _ = try await APIService.shared.createReminder(request: request)
                
                // Save Baseline/Target if provided
                if let val = Int(targetPefr), val >= 0 && val <= 900 {
                    _ = try await APIService.shared.setBaseline(baselineValue: val)
                }
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
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
    
    private func deleteNotification(_ notification: Notification) {
        withAnimation {
            dismissedIds.insert(notification.id)
            saveDismissedIds()
        }
    }
    
    private func saveDismissedIds() {
        UserDefaults.standard.set(Array(dismissedIds), forKey: dismissedIdsKey)
    }
    
    private func markAsRead(_ notification: Notification) {
        guard !notification.read else { return }
        Task {
            do {
                _ = try await APIService.shared.markNotificationRead(id: notification.id)
                let notifs = try await APIService.shared.getNotifications()
                await MainActor.run {
                    self.notifications = notifs.sorted(by: { $0.createdAt > $1.createdAt })
                }
            } catch {}
        }
    }
    
    private func calculateNextTrigger() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        guard let hour = comps.hour, let minute = comps.minute else { return nil }
        
        let todayTrigger = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!
        
        if frequency == "Daily" {
            return todayTrigger > now ? todayTrigger : calendar.date(byAdding: .day, value: 1, to: todayTrigger)
        } else if frequency == "Weekly" {
            let weekday = calendar.component(.weekday, from: now)
            var nextComps = DateComponents()
            nextComps.hour = hour
            nextComps.minute = minute
            nextComps.weekday = weekday
            return calendar.nextDate(after: now, matching: nextComps, matchingPolicy: .nextTime)
        } else if frequency == "Monthly" {
            let day = calendar.component(.day, from: now)
            var nextComps = DateComponents()
            nextComps.hour = hour
            nextComps.minute = minute
            nextComps.day = day
            return calendar.nextDate(after: now, matching: nextComps, matchingPolicy: .nextTime)
        }
        return nil
    }
    
    private func formatNextTrigger(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if calendar.isDateInToday(date) {
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(formatter.string(from: date))"
        } else {
            let df = DateFormatter()
            df.dateFormat = "MMM d, HH:mm"
            return df.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView(showMenu: .constant(false))
    }
}

struct RadioButton: View {
    let text: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: {
            selected = text
        }) {
            HStack(spacing: 8) {
                Image(systemName: selected == text ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selected == text ? .primaryColor : .gray)
                
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(.fieldTextColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationRow: View {
    let notification: Notification
    let onTap: () -> Void
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // Main content area
            HStack(spacing: 12) {
                Circle()
                    .fill(notification.read ? Color.clear : Color.accentColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.message)
                        .font(.system(size: 15, weight: notification.read ? .regular : .semibold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text(formatDate(notification.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            // Delete action button
            if let onDelete = onDelete {
                Button(action: {
                    withAnimation {
                        onDelete()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(notification.read ? Color.white.opacity(0.05) : Color.white.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .contextMenu {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Remove Locally", systemImage: "trash")
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        return DateUtils.formatDisplayDate(dateString, format: "dd MMM, HH:mm")
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}



struct ReportsView: View {
    @State private var user: User? = nil
    @State private var pefrRecords: [PEFRRecord] = []
    @State private var symptomRecords: [Symptom] = []
    
    @State private var isSharingEnabled = false
    @State private var showLinkDoctor = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var shareItem: ShareItem? = nil
    
    var patientId: Int? = nil
    private var isDoctorMode: Bool { return patientId != nil }
    
    // Symptom local dismissal filter
    @State private var dismissedSymptomIds: Set<Int> = []
    private var dismissedSymptomKey: String {
        if let pid = patientId { return "doctor_dismissed_symptoms_\(pid)" }
        return "patient_dismissed_symptoms"
    }
    
    var body: some View {
        ZStack {
            if isLoading { 
                ProgressView().tint(.white) 
            } else {
                VStack(spacing: 0) {
                    // Title "My Reports"
                    Text(isDoctorMode ? "Patient Report" : "My Reports")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 30)
                    
                    if !isDoctorMode {
                        // Real-Time Sharing
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Real-Time Sharing")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Tap to enable sharing")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Spacer()
                                Toggle("", isOn: $isSharingEnabled)
                                    .tint(.white)
                                    .labelsHidden()
                                    .onChange(of: isSharingEnabled) { _, newValue in
                                        if newValue { showLinkDoctor = true }
                                    }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Export Buttons
                    VStack(spacing: 16) {
                        ExportButton(title: "Export PDF Report", icon: nil, color: Color.accentColor.opacity(0.8)) {
                            generateReport(format: .pdf)
                        }
                        
                        ExportButton(title: "Export CSV Data", icon: "table", color: Color.accentColor.opacity(0.8)) {
                            generateReport(format: .csv)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryColor.ignoresSafeArea())
        .navigationTitle(isDoctorMode ? "Patient Report" : "Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadData)
        .sheet(isPresented: $showLinkDoctor) { LinkDoctorView() }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .alert("Error", isPresented: $showError) { 
            Button("OK", role: .cancel) {} 
        } message: { 
            Text(errorMessage) 
        }
    }
    
    private func loadData() {
        // Load dismissed IDs to filter report results
        if let savedSymptoms = UserDefaults.standard.array(forKey: dismissedSymptomKey) as? [Int] {
            self.dismissedSymptomIds = Set(savedSymptoms)
        }
        
        Task {
            do {
                if let pid = patientId {
                    async let profileReq = APIService.shared.getPatientProfile(patientId: pid)
                    async let pefrReq = APIService.shared.getPatientPefrRecords(patientId: pid)
                    async let symptomReq = APIService.shared.getPatientSymptomRecords(patientId: pid)
                    
                    let (profile, pefrs, symptoms) = try await (profileReq, pefrReq, symptomReq)
                    
                    await MainActor.run { 
                        self.user = profile
                        self.pefrRecords = pefrs.sorted(by: { $1.recordedAt < $0.recordedAt })
                        // Filter out dismissed symptoms
                        self.symptomRecords = symptoms
                            .filter { !dismissedSymptomIds.contains($0.id) }
                            .sorted(by: { $1.recordedAt < $0.recordedAt })
                        self.isLoading = false 
                    }
                } else {
                    async let profileReq = APIService.shared.getMyProfile()
                    async let pefrReq = APIService.shared.getMyPefrRecords()
                    async let symptomReq = APIService.shared.getMySymptomRecords()
                    
                    let (profile, pefrs, symptoms) = try await (profileReq, pefrReq, symptomReq)
                    
                    await MainActor.run { 
                        self.user = profile
                        self.pefrRecords = pefrs.sorted(by: { $1.recordedAt < $0.recordedAt })
                        // Filter out dismissed symptoms
                        self.symptomRecords = symptoms
                            .filter { !dismissedSymptomIds.contains($0.id) }
                            .sorted(by: { $1.recordedAt < $0.recordedAt })
                        self.isLoading = false 
                    }
                }
            } catch {
                await MainActor.run { self.isLoading = false; self.errorMessage = error.localizedDescription; self.showError = true }
            }
        }
    }
    
    enum ExportFormat { case csv, pdf }
    
    private func generateReport(format: ExportFormat) {
        if format == .csv {
            exportCSV()
        } else {
            exportPDF()
        }
    }
    
    private struct ReportRow {
        let date: Date
        var pefr: PEFRRecord?
        var symptom: Symptom?
    }

    private var groupedRows: [ReportRow] {
        var rows: [ReportRow] = []
        
        let allEvents: [(date: Date, pefr: PEFRRecord?, symptom: Symptom?)] = 
            pefrRecords.compactMap { r in 
                guard let d = DateUtils.parseRobustDate(r.recordedAt) else { return nil }
                return (d, r, nil)
            } + 
            symptomRecords.compactMap { s in
                guard let d = DateUtils.parseRobustDate(s.recordedAt) else { return nil }
                return (d, nil, s)
            }
        
        let sortedEvents = allEvents.sorted { $0.date > $1.date }
        
        for event in sortedEvents {
            // Check if there's a row within 5 minutes (300 seconds)
            if let index = rows.firstIndex(where: { abs($0.date.timeIntervalSince(event.date)) < 300 }) {
                if event.pefr != nil && rows[index].pefr == nil { rows[index].pefr = event.pefr }
                if event.symptom != nil && rows[index].symptom == nil { rows[index].symptom = event.symptom }
            } else {
                rows.append(ReportRow(date: event.date, pefr: event.pefr, symptom: event.symptom))
            }
        }
        return rows
    }

    private func exportCSV() {
        let rows = groupedRows
        let summary = "PEFR Titration Tracker - Patient Report\n" +
                      "Patient Name: \(user?.fullName ?? "N/A"), Baseline PEFR: \(user?.baseline?.baselineValue ?? 0)\n" +
                      "Generated On: \(Date().formatted())\n\n"
        
        var csvString = summary + "Timestamp,PEFR,Zone,Wheeze,Cough,Breath,Night,Chest,Activity,Puffs\n"
        
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy, HH:mm"
        df.timeZone = TimeZone.current

        for row in rows {
            let displayDate = df.string(from: row.date)
            let pefrValue = row.pefr.map { "\($0.pefrValue)" } ?? "-"
            let zone = row.pefr?.zone ?? "-"
            let wheeze = row.symptom.flatMap { $0.wheezeRating }.map { "\($0)" } ?? "-"
            let cough = row.symptom.flatMap { $0.coughRating }.map { "\($0)" } ?? "-"
            let breath = row.symptom.flatMap { $0.dyspneaRating }.map { "\($0)" } ?? "-"
            let night = row.symptom.flatMap { $0.nightSymptomsRating }.map { "\($0)" } ?? "-"
            let chest = row.symptom.flatMap { $0.chestTightnessRating }.map { "\($0)" } ?? "-"
            let activity = row.symptom.flatMap { $0.activityLimitationRating }.map { "\($0)" } ?? "-"
            let puffs = row.symptom.flatMap { $0.rescueInhalerPuffs }.map { "\($0)" } ?? "-"
            
            let line = [displayDate, pefrValue, zone, wheeze, cough, breath, night, chest, activity, puffs].joined(separator: ",")
            csvString += line + "\n"
        }
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("AsthmaData_\(DateUtils.formatDisplayDateShort(ISO8601DateFormatter().string(from: Date()))).csv")
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            self.shareItem = ShareItem(url: fileURL)
        } catch {
            self.errorMessage = "Failed to create CSV: \(error.localizedDescription)"
            self.showError = true
        }
    }
    
    private func exportPDF() {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let fileName = "Asthma_Report_\(Date().formatted(.dateTime.day().month().year())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let rows = groupedRows
            
        do {
            try pdfRenderer.writePDF(to: tempURL) { context in
                var pageNumber = 1
                context.beginPage()
                
                // 1. Hospital-Style Header with Logo
                if let logo = UIImage(named: "AppLogo") {
                    logo.draw(in: CGRect(x: 50, y: 40, width: 60, height: 60))
                }
                
                let appName = "PEFR Titration Tracker"
                let appNameAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.systemTeal]
                appName.draw(at: CGPoint(x: 120, y: 45), withAttributes: appNameAttr)
                
                let subTitle = "CLINICAL RESPIRATORY REPORT"
                let subTitleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.darkGray]
                subTitle.draw(at: CGPoint(x: 120, y: 72), withAttributes: subTitleAttr)
                
                // 2. Patient Information Grid
                UIColor.systemGray6.setFill()
                context.fill(CGRect(x: 50, y: 115, width: 512, height: 65))
                
                let patientInfo = "Patient: \(user?.fullName ?? "N/A")\nBaseline PEFR: \(user?.baseline?.baselineValue ?? 0) L/min\nGenerated: \(Date().formatted(date: .long, time: .shortened))"
                let infoAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
                patientInfo.draw(in: CGRect(x: 65, y: 125, width: 480, height: 50), withAttributes: infoAttr)
                
                // 3. Clinical Table
                var currentY: CGFloat = 205
                let headers = ["Date", "PEFR", "Whz", "Cgh", "Brth", "Ngt", "Chst", "Act", "Pfs"]
                let columnWidths: [CGFloat] = [95, 45, 45, 45, 45, 45, 45, 45, 45]
                
                // Header Background
                UIColor.systemTeal.withAlphaComponent(0.1).setFill()
                context.fill(CGRect(x: 50, y: currentY - 5, width: 512, height: 25))
                
                let headerAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
                for (i, header) in headers.enumerated() {
                    let x = headers.prefix(i).indices.reduce(50) { $0 + columnWidths[$1] }
                    header.draw(at: CGPoint(x: x + 5, y: currentY), withAttributes: headerAttr)
                }
                
                currentY += 25
                
                // Rows
                let rowAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.black]
                
                let df = DateFormatter()
                df.dateFormat = "dd MMM, HH:mm"
                df.timeZone = TimeZone.current

                for (index, row) in rows.enumerated() {
                    if currentY > 720 { 
                        addFooter(to: context, pageNumber: pageNumber)
                        pageNumber += 1
                        context.beginPage()
                        currentY = 50 
                    }
                    
                    // Alternating Row Colors
                    if index % 2 == 1 {
                        UIColor.systemGray6.withAlphaComponent(0.5).setFill()
                        context.fill(CGRect(x: 50, y: currentY - 2, width: 512, height: 20))
                    }
                    
                    let displayDate = df.string(from: row.date)
                    let pefrVal = row.pefr.map { "\($0.pefrValue)" } ?? "-"
                    let wheeze = row.symptom.flatMap { $0.wheezeRating }.map { "\($0)" } ?? "-"
                    let cough = row.symptom.flatMap { $0.coughRating }.map { "\($0)" } ?? "-"
                    let breath = row.symptom.flatMap { $0.dyspneaRating }.map { "\($0)" } ?? "-"
                    let night = row.symptom.flatMap { $0.nightSymptomsRating }.map { "\($0)" } ?? "-"
                    let chest = row.symptom.flatMap { $0.chestTightnessRating }.map { "\($0)" } ?? "-"
                    let activity = row.symptom.flatMap { $0.activityLimitationRating }.map { "\($0)" } ?? "-"
                    let puffs = row.symptom.flatMap { $0.rescueInhalerPuffs }.map { "\($0)" } ?? "-"
                    
                    let values: [String] = [displayDate, pefrVal, wheeze, cough, breath, night, chest, activity, puffs]
                    
                    for (i, val) in values.enumerated() {
                        let x = values.prefix(i).indices.reduce(50) { $0 + columnWidths[$1] }
                        val.draw(at: CGPoint(x: x + 5, y: currentY), withAttributes: rowAttr)
                    }
                    currentY += 20
                }
                
                addFooter(to: context, pageNumber: pageNumber)
            }
            
            self.shareItem = ShareItem(url: tempURL)
        } catch {
            self.errorMessage = "Failed to create PDF: \(error.localizedDescription)"
            self.showError = true
        }
    }
    
    private func addFooter(to context: UIGraphicsPDFRendererContext, pageNumber: Int) {
        let footer = "Page \(pageNumber) | Auto-generated by PEFR Titration Tracker"
        let footerAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.lightGray]
        footer.draw(at: CGPoint(x: 50, y: 760), withAttributes: footerAttr)
    }
}

struct ExportButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(color)
            .cornerRadius(16)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
