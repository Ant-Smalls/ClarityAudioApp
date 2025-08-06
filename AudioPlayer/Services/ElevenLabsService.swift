import Foundation

enum ElevenLabsError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case audioConversionFailed
}

class ElevenLabsService {
    static let shared = ElevenLabsService()
    
    private init() {}
    
    func synthesizeSpeech(text: String, voiceId: String) async throws -> Data {
        // If using custom voice, get it from UserDefaults
        let finalVoiceId: String
        if voiceId == "custom" {
            if let customVoiceId = UserDefaults.standard.string(forKey: "customVoiceId") {
                finalVoiceId = customVoiceId
            } else {
                throw NSError(
                    domain: "ElevenLabsService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Custom voice ID not found. Please set up your voice clone first."]
                )
            }
        } else {
            finalVoiceId = voiceId
        }
        
        let apiKey = APIConfig.elevenLabsApiKey
        let endpoint = "\(APIConfig.elevenLabsBaseURL)/\(finalVoiceId)"
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "ElevenLabsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ElevenLabsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "ElevenLabsService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Failed to synthesize speech. Status code: \(httpResponse.statusCode)"]
            )
        }
        
        return data
    }
    
    // Optional: Add method to verify voice ID
    func verifyVoiceId(_ voiceId: String) async throws -> Bool {
        let apiKey = APIConfig.elevenLabsApiKey
        let endpoint = "https://api.elevenlabs.io/v1/voices/\(voiceId)"
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "ElevenLabsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        return httpResponse.statusCode == 200
    }
} 