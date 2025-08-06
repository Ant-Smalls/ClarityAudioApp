import Foundation

class CustomVoiceManager {
    static let shared = CustomVoiceManager()
    private let customVoicesKey = "customVoices"
    private let activeCustomVoiceKey = "activeCustomVoice"
    
    private init() {}
    
    // MARK: - Voice Management
    
    func saveCustomVoice(_ voice: CustomVoice) throws {
        var voices = getCustomVoices()
        voices.append(voice)
        try saveVoices(voices)
        NotificationCenter.default.post(name: Notification.Name("CustomVoiceUpdated"), object: nil)
    }
    
    func updateCustomVoice(_ voice: CustomVoice) throws {
        var voices = getCustomVoices()
        if let index = voices.firstIndex(where: { $0.id == voice.id }) {
            voices[index] = voice
            try saveVoices(voices)
            NotificationCenter.default.post(name: Notification.Name("CustomVoiceUpdated"), object: nil)
        }
    }
    
    func deleteCustomVoice(withId id: UUID) throws {
        var voices = getCustomVoices()
        voices.removeAll { $0.id == id }
        try saveVoices(voices)
        
        // If this was the active voice, clear it
        if let activeVoice = getActiveCustomVoice(), activeVoice.id == id {
            clearActiveCustomVoice()
        }
        NotificationCenter.default.post(name: Notification.Name("CustomVoiceUpdated"), object: nil)
    }
    
    func getCustomVoices() -> [CustomVoice] {
        guard let data = UserDefaults.standard.data(forKey: customVoicesKey),
              let voices = try? JSONDecoder().decode([CustomVoice].self, from: data) else {
            return []
        }
        return voices.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    // MARK: - Active Voice Management
    
    func setActiveCustomVoice(_ voice: CustomVoice) {
        guard let data = try? JSONEncoder().encode(voice) else { return }
        UserDefaults.standard.set(data, forKey: activeCustomVoiceKey)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name("CustomVoiceUpdated"), object: nil)
    }
    
    func getActiveCustomVoice() -> CustomVoice? {
        guard let data = UserDefaults.standard.data(forKey: activeCustomVoiceKey),
              let voice = try? JSONDecoder().decode(CustomVoice.self, from: data) else {
            return nil
        }
        // Verify that the voice still exists in saved voices
        let voices = getCustomVoices()
        guard voices.contains(where: { $0.id == voice.id }) else {
            clearActiveCustomVoice()
            return nil
        }
        return voice
    }
    
    func clearActiveCustomVoice() {
        UserDefaults.standard.removeObject(forKey: activeCustomVoiceKey)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name("CustomVoiceUpdated"), object: nil)
    }
    
    // MARK: - Private Helpers
    
    private func saveVoices(_ voices: [CustomVoice]) throws {
        let data = try JSONEncoder().encode(voices)
        UserDefaults.standard.set(data, forKey: customVoicesKey)
        UserDefaults.standard.synchronize()
    }
} 