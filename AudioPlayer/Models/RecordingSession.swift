import Foundation

struct RecordingSession: Identifiable {
    let id: UUID
    let name: String
    let dateCreated: Date
    let duration: TimeInterval
    let audioFileName: String
    let sourceLanguage: String
    let targetLanguage: String
    let transcription: String
    let translation: String
    var isStarred: Bool = false
    
    init(id: UUID = UUID(), 
         name: String, 
         dateCreated: Date = Date(),
         duration: TimeInterval,
         audioFileName: String,
         sourceLanguage: String,
         targetLanguage: String,
         transcription: String,
         translation: String) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.duration = duration
        self.audioFileName = audioFileName
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.transcription = transcription
        self.translation = translation
    }
} 