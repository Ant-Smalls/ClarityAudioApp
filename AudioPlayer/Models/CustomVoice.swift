import Foundation

struct CustomVoice: Codable, Identifiable {
    let id: UUID
    let name: String
    let voiceId: String
    let dateAdded: Date
    
    init(name: String, voiceId: String) {
        self.id = UUID()
        self.name = name
        self.voiceId = voiceId
        self.dateAdded = Date()
    }
} 