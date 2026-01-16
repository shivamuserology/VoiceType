import Foundation
import Security

/// Service for interacting with Gemini Flash API
class GeminiService {
    
    // MARK: - Keychain Keys
    
    private static let keychainService = "com.voicetype.gemini"
    private static let keychainAccount = "api-key"
    
    // MARK: - API Configuration
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    // MARK: - Default System Prompt
    
    static let defaultSystemPrompt = """
    Rewrite the following text to be clearer and better structured.
    Preserve the original meaning and intent completely.
    Do not add new information or change the message.
    Keep the same tone and formality level.
    """
    
    // MARK: - Errors
    
    enum GeminiError: Error, LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case emptyResponse
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Gemini API key not configured. Please add it in Settings."
            case .invalidURL:
                return "Invalid API URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from Gemini API"
            case .apiError(let message):
                return "API error: \(message)"
            case .emptyResponse:
                return "Empty response from Gemini API"
            case .rateLimited:
                return "Rate limited. Try again in a few seconds."
            }
        }
    }
    
    // MARK: - Keychain Operations
    
    /// Save API key to Keychain
    static func saveAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve API key from Keychain
    static func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Check if API key exists
    static func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
    
    /// Delete API key from Keychain
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Rewrite Text
    
    /// Rewrite text using Gemini Flash
    /// - Parameters:
    ///   - text: The text to rewrite
    ///   - systemPrompt: Custom system instruction (uses default if nil)
    /// - Returns: Rewritten text
    func rewriteText(_ text: String, systemPrompt: String? = nil) async throws -> String {
        guard let apiKey = GeminiService.getAPIKey() else {
            throw GeminiError.noAPIKey
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let prompt = systemPrompt ?? GeminiService.defaultSystemPrompt
        let fullPrompt = "\(prompt)\n\nText to rewrite:\n\(text)"
        
        // Build request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("[GeminiService] Sending rewrite request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                // Handle rate limiting specifically
                if httpResponse.statusCode == 429 {
                    print("[GeminiService] Rate limited (429)")
                    throw GeminiError.rateLimited
                }
                
                if let errorBody = String(data: data, encoding: .utf8) {
                    print("[GeminiService] API Error: \(errorBody)")
                    throw GeminiError.apiError("Status \(httpResponse.statusCode)")
                }
                throw GeminiError.apiError("Status code: \(httpResponse.statusCode)")
            }
            
            // Parse response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let rewrittenText = firstPart["text"] as? String else {
                throw GeminiError.invalidResponse
            }
            
            let trimmedText = rewrittenText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedText.isEmpty else {
                throw GeminiError.emptyResponse
            }
            
            print("[GeminiService] Rewrite complete: \(trimmedText.prefix(50))...")
            return trimmedText
            
        } catch let error as GeminiError {
            throw error
        } catch {
            throw GeminiError.networkError(error)
        }
    }
}
