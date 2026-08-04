import Foundation
//uvicorn main:app --reload
//uvicorn main:app --host 0.0.0.0 --port 8000 --reload
//180.235.121.253:8062
class NetworkManager {
    static let shared = NetworkManager()
    
    // Dynamic Base URL
    private var baseURL: String {
        return "http://180.235.121.253:8062/"
        //return "http://180.235.121.253:8062/"
        //return "http://1    .25.88.228:8000/"
    }
    
    private init() {}
    
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }
    
    enum NetworkError: Error, LocalizedError {  
        case invalidURL
        case noData
        case decodingError
        case serverError(String)
        case unauthorized
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .noData: return "No data received"
            case .decodingError: return "Failed to decode response"
            case .serverError(let message): return message
            case .unauthorized: return "Invalid email or password"
            }
        }
    }
    
    // MARK: - Generic Request
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        // Always fetch fresh data from server — never use iOS URLSession response cache.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Add auth token if required
        if requiresAuth, let token = SessionManager.shared.fetchAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if present
        if let body = body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("Invalid response")
            }
            
            // Handle different status codes
            if (200...299).contains(httpResponse.statusCode) {
                // Success
            } else {
                if let serverError = parseError(from: data) {
                    throw NetworkError.serverError(serverError)
                }
                
                if httpResponse.statusCode == 401 {
                    await SessionManager.shared.clearSession()
                    throw NetworkError.unauthorized
                }
                throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingError
            }
        } catch let error as URLError {
            if error.code == .timedOut {
                throw NetworkError.serverError("The server is taking too long to respond. Please check your connection.")
            } else if error.code == .notConnectedToInternet {
                throw NetworkError.serverError("No internet connection detected.")
            } else {
                throw NetworkError.serverError("Network error: \(error.localizedDescription)")
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Form URL Encoded Request (for login)
    func formRequest<T: Decodable>(
        endpoint: String,
        parameters: [String: String],
        requiresAuth: Bool = false
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        
        // Add auth token if required
        if requiresAuth, let token = SessionManager.shared.fetchAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create form body with proper URL encoding
        var components = URLComponents()
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = components.query?.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("Invalid response")
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let serverError = parseError(from: data) {
                    throw NetworkError.serverError(serverError)
                }
                
                if httpResponse.statusCode == 401 {
                    await SessionManager.shared.clearSession()
                    throw NetworkError.unauthorized
                }
                throw NetworkError.serverError("Server error: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as URLError {
            if error.code == .timedOut {
                throw NetworkError.serverError("Login server is taking too long to respond. Please check your connection.")
            } else if error.code == .notConnectedToInternet {
                throw NetworkError.serverError("No internet connection detected.")
            } else {
                throw error
            }
        } catch {
            print("Network request failed for \(url.absoluteString): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func parseError(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        if let detail = json["detail"] as? String {
            return detail
        } else if let errorMsg = json["error"] as? String {
            return errorMsg
        } else if let detailArray = json["detail"] as? [[String: Any]],
                  let firstError = detailArray.first,
                  let msg = firstError["msg"] as? String {
            return msg
        } else if let message = json["message"] as? String {
            return message
        }
        
        return nil
    }
}
