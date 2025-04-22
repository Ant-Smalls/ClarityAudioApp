import Foundation

class APIKeyManager {
    static let shared = APIKeyManager()
    
    private let elevenLabsApiKeyKey = "user_eleven_labs_api_key"
    
    private init() {}
    
    func setElevenLabsApiKey(_ apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: elevenLabsApiKeyKey)
        UserDefaults.standard.synchronize()
    }
    
    func getElevenLabsApiKey() -> String? {
        return UserDefaults.standard.string(forKey: elevenLabsApiKeyKey)
    }
    
    func clearElevenLabsApiKey() {
        UserDefaults.standard.removeObject(forKey: elevenLabsApiKeyKey)
        UserDefaults.standard.synchronize()
    }
} 