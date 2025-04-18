import Foundation
import SwiftUI

class CustomVoiceViewModel: ObservableObject {
    @Published var customVoices: [CustomVoice] = []
    @Published var activeVoice: CustomVoice?
    @Published var showingAddVoiceSheet = false
    @Published var showingEditVoiceSheet = false
    @Published var selectedVoiceForEdit: CustomVoice?
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let voiceManager = CustomVoiceManager.shared
    
    init() {
        loadVoices()
        // Set up notification observer for voice updates
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleVoiceUpdate),
                                            name: Notification.Name("CustomVoiceUpdated"),
                                            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleVoiceUpdate() {
        loadVoices()
    }
    
    func loadVoices() {
        customVoices = voiceManager.getCustomVoices()
        activeVoice = voiceManager.getActiveCustomVoice()
    }
    
    func addCustomVoice(name: String, voiceId: String) {
        do {
            let newVoice = CustomVoice(name: name, voiceId: voiceId)
            try voiceManager.saveCustomVoice(newVoice)
            loadVoices()
        } catch {
            showError("Failed to save custom voice: \(error.localizedDescription)")
        }
    }
    
    func updateCustomVoice(_ voice: CustomVoice, newName: String) {
        do {
            let updatedVoice = CustomVoice(name: newName, voiceId: voice.voiceId)
            try voiceManager.updateCustomVoice(updatedVoice)
            loadVoices()
        } catch {
            showError("Failed to update custom voice: \(error.localizedDescription)")
        }
    }
    
    func deleteCustomVoice(_ voice: CustomVoice) {
        do {
            try voiceManager.deleteCustomVoice(withId: voice.id)
            loadVoices()
        } catch {
            showError("Failed to delete custom voice: \(error.localizedDescription)")
        }
    }
    
    func setActiveVoice(_ voice: CustomVoice?) {
        if let voice = voice {
            voiceManager.setActiveCustomVoice(voice)
        } else {
            voiceManager.clearActiveCustomVoice()
        }
        activeVoice = voice
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
} 