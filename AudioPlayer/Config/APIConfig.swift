import Foundation

struct APIConfig {
    // ElevenLabs Configuration
    static let elevenLabsBaseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    static let elevenLabsVoiceID = "21m00Tcm4TlvDq8ikWAM"
    
    static var elevenLabsApiKey: String {
        // First try to get user-set API key
        if let userApiKey = APIKeyManager.shared.getElevenLabsApiKey() {
            return userApiKey
        }
        
        // Fallback to Info.plist key
        guard let apiKey = Bundle.main.infoDictionary?["ELEVEN_LABS_API_KEY"] as? String else {
            fatalError("ELEVEN_LABS_API_KEY not found in Info.plist")
        }
        return apiKey
    }
} 