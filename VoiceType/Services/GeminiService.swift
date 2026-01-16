import Foundation
import GoogleGenerativeAI

/// Service for interacting with Gemini Flash API via GoogleGenerativeAI SDK
class GeminiService {
    
    // MARK: - Keychain Keys
    
    private static let keychainService = "com.voicetype.gemini"
    private static let keychainAccount = "api-key"
    
    // MARK: - Legacy Constants
    
    // baseURL is handled by the SDK
    
    /// Models to try in order (fallback chain for rate limiting)
    private let modelChain = [
        "gemini-2.0-flash",     // Primary
        "gemini-1.5-flash-8b",  // Faster fallback
        "gemini-1.5-flash"      // Standard fallback
    ]
    
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
        case apiError(String)
        case emptyResponse
        case allModelsRateLimited
        case sdkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Gemini API key not configured"
            case .apiError(let message):
                return message
            case .emptyResponse:
                return "Empty response from API"
            case .allModelsRateLimited:
                return "Rate limited - try again later"
            case .sdkError(let error):
                return "AI Error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - API Key Storage (UserDefaults)
    
    /// Save API key to UserDefaults
    static func saveAPIKey(_ key: String) -> Bool {
        UserDefaults.standard.set(key, forKey: keychainAccount)
        return true
    }
    
    /// Retrieve API key from UserDefaults
    static func getAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: keychainAccount)
    }
    
    /// Check if API key exists
    static func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
    
    /// Delete API key
    static func deleteAPIKey() -> Bool {
        UserDefaults.standard.removeObject(forKey: keychainAccount)
        return true
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
        
        let sysPromptText = systemPrompt ?? GeminiService.defaultSystemPrompt
        
        // Try each model in the chain
        for (index, modelName) in modelChain.enumerated() {
            do {
                print("[GeminiService] Trying model: \(modelName)")
                return try await callModelSDK(modelName: modelName, apiKey: apiKey, prompt: text, systemPrompt: sysPromptText)
            } catch {
                print("[GeminiService] Error on \(modelName): \(error.localizedDescription)")
                
                // Check if it's a rate limit error (SDK errors might wrap it)
                let errorStr = "\(error)".lowercased()
                if errorStr.contains("429") || errorStr.contains("resourceexhausted") {
                    print("[GeminiService] Rate limited, trying next...")
                    if index == modelChain.count - 1 {
                        throw GeminiError.allModelsRateLimited
                    }
                    continue
                }
                
                // If it's the last model, throw
                if index == modelChain.count - 1 {
                    throw GeminiError.sdkError(error)
                }
            }
        }
        
        throw GeminiError.allModelsRateLimited
    }
    
    /// Call a specific model using the SDK
    private func callModelSDK(modelName: String, apiKey: String, prompt: String, systemPrompt: String) async throws -> String {
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 2048,
            responseMIMEType: "text/plain"
        )
        
        let model = GenerativeModel(
            name: modelName,
            apiKey: apiKey,
            generationConfig: config,
            systemInstruction: ModelContent(role: "system", parts: [.text(systemPrompt)])
        )
        
        // Use streaming to filter thinking tokens if present (following user pattern)
        let stream = model.generateContentStream(prompt)
        var finalOutput = ""
        
        for try await chunk in stream {
            for candidate in chunk.candidates {
                for part in candidate.content.parts {
                    // Only process text parts
                    if case .text(let text) = part {
                        // In the future, if specific thinking parts need filtering logic, add checks here.
                        // Currently we assume standard text parts are the output.
                        finalOutput += text
                    }
                }
            }
        }
        
        let trimmed = finalOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw GeminiError.emptyResponse
        }
        
        print("[GeminiService] Rewrite complete with \(modelName): \(trimmed.prefix(50))...")
        return trimmed
    }
}
