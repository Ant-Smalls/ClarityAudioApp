import Foundation

enum RecordingSortOption {
    case dateCreated
    
    var sortDescriptor: (RecordingSession, RecordingSession) -> Bool {
        return { $0.dateCreated > $1.dateCreated } // Newest first
    }
} 