import Foundation
import Security

/// Service for interacting with Gemini Flash API
class GeminiService {
    
    // MARK: - Keychain Keys
    
    private static let keychainService = "com.voicetype.gemini"
    private static let keychainAccount = "api-key"
    
    // MARK: - API Configuration
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    /// Models to try in order (fallback chain for rate limiting)
    private let modelChain = [
        "gemini-2.0-flash",
        "gemini-1.5-flash-8b",
        "gemini-1.5-flash"
    ]
    
    // MARK: - Default System Prompt
    
    // MARK: - Default System Prompt
    
    static let defaultSystemPrompt = """
    Rewrite the following text to be clearer and better structured.
    Fix all typos and transcription issues based best judgement. Fix grammatical errors if any.  
    Do not add new information or change the message Preserve the original meaning, flow and order of information, and intent completely.
    Keep the same tone, detail and formality level. Just output 1 final re-written text and nothing else, don't output multiple items.
    """
    
    // MARK: - Errors
    
    enum GeminiError: Error, LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case emptyResponse
        case allModelsRateLimited
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Gemini API key not configured"
            case .invalidURL:
                return "Invalid API URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from API"
            case .apiError(let message):
                return message
            case .emptyResponse:
                return "Empty response from API"
            case .allModelsRateLimited:
                return "Rate limited - try again later"
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
            kSecValueData as String: data,
            // Allow access without prompt after first unlock
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
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
    
    /// Rewrite text using Gemini Flash with automatic fallback
    /// - Parameters:
    ///   - text: The text to rewrite
    ///   - systemPrompt: Custom system instruction (uses default if nil)
    /// - Returns: Rewritten text
    func rewriteText(_ text: String, systemPrompt: String? = nil) async throws -> String {
        guard let apiKey = GeminiService.getAPIKey() else {
            throw GeminiError.noAPIKey
        }
        
        let sysPrompt = systemPrompt ?? GeminiService.defaultSystemPrompt
        
        // Try each model in the chain
        for (index, model) in modelChain.enumerated() {
            do {
                print("[GeminiService] Trying model: \(model)")
                // Pass system prompt separately
                let result = try await callModel(model: model, apiKey: apiKey, prompt: text, systemPrompt: sysPrompt)
                return result
            } catch GeminiError.apiError(let message) where message.contains("429") {
                print("[GeminiService] Rate limited on \(model), trying next...")
                if index == modelChain.count - 1 {
                    throw GeminiError.allModelsRateLimited
                }
                continue
            }
        }
        
        throw GeminiError.allModelsRateLimited
    }
    
    /// Call a specific model
    private func callModel(model: String, apiKey: String, prompt: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        // Build request body with system instruction
        var requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048
            ]
        ]
        
        // Add system instruction if supported by the model (Flash 1.5+ supports it)
        if !systemPrompt.isEmpty {
            requestBody["systemInstruction"] = [
                "parts": [
                    ["text": systemPrompt]
                ]
            ]
        }

        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw GeminiError.apiError("429 Rate Limited")
        }
        
        if httpResponse.statusCode != 200 {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("[GeminiService] API Error: \(errorBody)")
            }
            throw GeminiError.apiError("Status \(httpResponse.statusCode)")
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
        
        print("[GeminiService] Rewrite complete with \(model): \(trimmedText.prefix(50))...")
        return trimmedText
    }
}
