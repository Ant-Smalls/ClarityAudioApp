import Foundation

struct APIConfig {
    // ElevenLabs Configuration
    static let elevenLabsBaseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    static let elevenLabsVoiceID = "21m00Tcm4TlvDq8ikWAM"
    
    // Add your API key in a secure way - DO NOT commit the actual key
    static var elevenLabsAPIKey: String {
        // First try Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ELEVEN_LABS_API_KEY") as? String,
           !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE" {
            return apiKey
        }
        
        // Then try environment variable
        if let apiKey = ProcessInfo.processInfo.environment["ELEVEN_LABS_API_KEY"],
           !apiKey.isEmpty {
            return apiKey
        }
        
        fatalError("""
            Missing ElevenLabs API key. Please add your API key in one of these ways:
            1. Add ELEVEN_LABS_API_KEY to Info.plist
            2. Set ELEVEN_LABS_API_KEY environment variable
            You can get an API key from: https://elevenlabs.io/
            """)
    }
} 