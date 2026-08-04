import Foundation

class AIService {
    static let shared = AIService()
    private let apiKey = "YOUR_OPENROUTER_API_KEY_HERE"
    private let openRouterURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    
    private init() {}
    
    func getAIResponse(messages: [ChatMessage], context: String) async throws -> String {
        // Prepare messages for API
        var apiMessages: [[String: String]] = []
        
        // Add System Prompt with context
        let systemPrompt = """
        You are an AI Health Advisor for "PEFR Tracker", a specialized asthma management app. 
        Your role is to provide personalized, data-driven guidance to help patients manage their respiratory health.

        CORE CAPABILITIES:
        1. Analyze PEFR (Peak Flow) trends, symptoms, and medication usage.
        2. Provide actionable advice based on the patient's current "Zone" (Green/Yellow/Red).
        3. Explain how external factors (weather, infections, triggers) and common medications might impact asthma.
        
        STRICT SAFETY GUIDELINES:
        1. If PEFR is in the Red Zone (<50% of baseline), prioritize advising immediate medical attention.
        2. Do not prescribe new medications or change dosage.
        3. Clarify that you are an AI assistant and not a replacement for professional medical diagnosis.
        4. If asked about common non-asthma medications (like Paracetamol/Dolo), explain their general use (e.g., managing fever/pain) and how those symptoms might relate to asthma triggers (like viral infections), but always refer to their doctor for specific usage.

        Current Patient Context:
        \(context)

        Response Style:
        - Professional, empathetic, and data-centric.
        - Use Markdown (bullets, bold text) for clarity.
        - Be concise but thorough in explaining "why" behind the advice.
        """
        
        apiMessages.append(["role": "system", "content": systemPrompt])
        
        // Add chat history
        for msg in messages {
            let role = msg.role == .user ? "user" : "assistant"
            apiMessages.append(["role": role, "content": msg.content])
        }
        
        let body: [String: Any] = [
            "model": "google/gemini-2.0-flash-lite-001",
            "messages": apiMessages,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: openRouterURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("https://pefr-tracker.example.com", forHTTPHeaderField: "HTTP-Referer")
        request.addValue("PEFR Tracker", forHTTPHeaderField: "X-Title")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("AI Error: \(errorMsg)")
            throw NSError(domain: "AIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "AI Error (\(httpResponse.statusCode)): \(errorMsg)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let choice = choices?.first
        let message = choice?["message"] as? [String: Any]
        
        guard let content = message?["content"] as? String else {
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response content"])
        }
        
        return content
    }
}
