import Foundation

class AudioFileManager {
    static let shared = AudioFileManager()
    
    private init() {}
    
    func saveAudioFile(sourceURL: URL, withName name: String) throws -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(name)_\(Date().timeIntervalSince1970).m4a"
        let destinationURL = documentsPath.appendingPathComponent(fileName)
        
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        return fileName
    }
    
    func deleteAudioFile(fileName: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func getAudioFileURL(fileName: String) -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
} 