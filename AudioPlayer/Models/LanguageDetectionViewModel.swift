import Foundation
import Combine

class LanguageDetectionViewModel: ObservableObject {
    private let languageService = LanguageDetectionService.shared
    
    @Published var detectedLanguage: (code: String, name: String)? = nil
    @Published var isLanguageAvailable: Bool = false
    @Published var showDownloadPrompt: Bool = false
    
    // Called when new transcription is available
    func processTranscription(_ text: String) {
        let (languageCode, isSupported) = languageService.detectLanguage(text)
        
        guard let code = languageCode, isSupported else {
            // Language detection failed or unsupported language
            detectedLanguage = nil
            isLanguageAvailable = false
            return
        }
        
        let name = languageService.getLanguageName(for: code)
        detectedLanguage = (code: code, name: name)
        isLanguageAvailable = languageService.isLanguageAvailable(code)
        
        // Show download prompt if language is not available
        if !isLanguageAvailable {
            showDownloadPrompt = true
        }
    }
    
    // Check if a specific language is supported
    func isLanguageSupported(_ languageCode: String) -> Bool {
        return languageService.supportedLanguages.contains(languageCode)
    }
    
    // Get the list of supported languages with their status
    func getSupportedLanguages() -> [(code: String, name: String, isAvailable: Bool)] {
        return languageService.getSupportedLanguagesStatus()
    }
} 