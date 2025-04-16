import Foundation
import NaturalLanguage
import AVFAudio

class LanguageDetectionService {
    static let shared = LanguageDetectionService()
    
    // List of languages supported by our app
    let supportedLanguages: [String] = ["en", "es", "fr", "de", "it", "pt", "ru", "ko", "ja"]
    
    private init() {}
    
    /// Detects the language of the given text
    /// - Parameter text: The text to analyze
    /// - Returns: A tuple containing the detected language code and whether it's supported
    func detectLanguage(_ text: String) -> (languageCode: String?, isSupported: Bool) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let detectedLanguage = recognizer.dominantLanguage?.rawValue else {
            return (nil, false)
        }
        
        let isSupported = supportedLanguages.contains(detectedLanguage)
        return (detectedLanguage, isSupported)
    }
    
    /// Checks if a language is downloaded and available for use
    /// - Parameter languageCode: The language code to check
    /// - Returns: Boolean indicating if the language is available
    func isLanguageAvailable(_ languageCode: String) -> Bool {
        let availableLanguages = AVSpeechSynthesisVoice.speechVoices().map { $0.language }
        return availableLanguages.contains(languageCode)
    }
    
    /// Gets a user-friendly name for a language code
    /// - Parameter languageCode: The ISO language code
    /// - Returns: A readable language name
    func getLanguageName(for languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode) ?? languageCode
    }
    
    /// Gets all supported languages with their availability status
    /// - Returns: Array of tuples containing language code, name, and availability
    func getSupportedLanguagesStatus() -> [(code: String, name: String, isAvailable: Bool)] {
        return supportedLanguages.map { code in
            (
                code: code,
                name: getLanguageName(for: code),
                isAvailable: isLanguageAvailable(code)
            )
        }
    }
} 