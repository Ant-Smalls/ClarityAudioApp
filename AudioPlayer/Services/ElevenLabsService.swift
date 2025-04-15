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
    
    func synthesizeSpeech(text: String, voiceId: String = APIConfig.elevenLabsVoiceID) async throws -> Data {
        let url = "\(APIConfig.elevenLabsBaseURL)/\(voiceId)"
        guard let requestUrl = URL(string: url) else {
            throw ElevenLabsError.invalidURL
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ElevenLabsError.invalidResponse
            }
            
            return data
        } catch {
            throw ElevenLabsError.requestFailed(error)
        }
    }
} 