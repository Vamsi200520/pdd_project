import SwiftUI
import Combine

struct AIAgentView: View {
    @Binding var showMenu: Bool
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hello! I am your AI Health Advisor. I can help you verify your doctor's prescriptions based on your symptoms and PEFR data. How can I assist you today?")
    ]
    @State private var inputText: String = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                
                VStack(spacing: 4) {
                    Text("AI Health Advisor")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Always online")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.greenZone)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.primaryColor)
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .id("typing")
                        }
                    }
                    .padding(.vertical, 20)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: isLoading) { newValue in
                    if newValue {
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(hex: "#F5F7F9"))
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Ask about your treatment...", text: $inputText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.primaryColor)
                        .clipShape(Circle())
                        .shadow(color: Color.primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .navigationBarHidden(true)
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        
        Task {
            do {
                // Fetch relevant health data for context
                async let profileReq = APIService.shared.getMyProfile()
                async let recordsReq = APIService.shared.getMyPefrRecords()
                async let symptomsReq = APIService.shared.getMySymptomRecords()
                async let medsReq = APIService.shared.getMedications()
                
                let (user, pefrList, symptomList, medList) = try await (profileReq, recordsReq, symptomsReq, medsReq)
                
                // Construct context string
                let calendar = Calendar.current
                
                // Process PEFR records (Latest 10 for trend analysis)
                let latestPefrs = Array(pefrList.sorted(by: { $0.recordedAt > $1.recordedAt }).prefix(10))
                
                // Process Symptom records (Latest 10)
                let latestSymptoms = Array(symptomList.sorted(by: { $0.recordedAt > $1.recordedAt }).prefix(10))
                
                let activeMeds = medList.map { "\($0.name) (\($0.dose ?? "N/A"))" }.joined(separator: ", ")
                
                var context = "Patient Name: \(user.fullName ?? "User"), Age: \(user.age ?? 0), Height: \(user.height ?? 0) cm.\n"
                context += "Baseline PEFR: \(user.baseline?.baselineValue ?? 0)\n\n"
                
                // PEFR Summary
                if !latestPefrs.isEmpty {
                    context += "Recent PEFR History (Latest \(latestPefrs.count)):\n"
                    for record in latestPefrs {
                        let date = DateUtils.formatDisplayDate(record.recordedAt, format: "MMM d, HH:mm")
                        context += "- \(date): \(record.pefrValue) L/min (Zone: \(record.zone))\n"
                    }
                } else {
                    context += "No PEFR records available.\n"
                }
                
                // Symptoms Summary
                if !latestSymptoms.isEmpty {
                    context += "\nRecent Symptoms History:\n"
                    for s in latestSymptoms {
                        let date = DateUtils.formatDisplayDate(s.recordedAt, format: "MMM d, HH:mm")
                        context += "- \(date): Wheeze \(s.wheezeRating ?? 0)/3, Cough \(s.coughRating ?? 0)/3, SOB \(s.dyspneaRating ?? 0)/3, Night \(s.nightSymptomsRating ?? 0)/3\n"
                    }
                } else {
                    context += "\nNo recent symptoms recorded.\n"
                }
                
                context += "\nActive Medications: \(activeMeds.isEmpty ? "None" : activeMeds)\n"
                
                // Get AI response using history
                let aiResponse = try await AIService.shared.getAIResponse(messages: messages, context: context)
                
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: aiResponse))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: "I'm sorry, I'm having trouble connecting to my knowledge base right now. Please try again later."))
                    print("AI Error: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Components

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(LocalizedStringKey(message.content))
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .foregroundColor(message.role == .user ? .white : .black)
                    .background(message.role == .user ? Color.primaryColor : Color.white)
                    .cornerRadius(18, corners: message.role == .user ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant { Spacer() }
        }
        .padding(.horizontal, 20)
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray.opacity(index == dotCount ? 1 : 0.4))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    AIAgentView(showMenu: .constant(false))
}
