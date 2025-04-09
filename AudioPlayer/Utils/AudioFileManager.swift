import Foundation
import AVFoundation

enum AudioFileError: Error {
    case saveFailed
    case loadFailed
    case deleteFailed
    case invalidURL
}

class AudioFileManager {
    static let shared = AudioFileManager()
    
    private init() {}
    
    private var audioDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("AudioRecordings", isDirectory: true)
    }
    
    func setup() {
        do {
            try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Error creating audio directory: \(error)")
        }
    }
    
    func saveAudioFile(sourceURL: URL, withName name: String) throws -> String {
        setup()
        let fileName = "\(name)_\(UUID().uuidString).m4a"
        let destinationURL = audioDirectory.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(at: destinationURL) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return fileName
        } catch {
            print("❌ Error saving audio file: \(error)")
            throw AudioFileError.saveFailed
        }
    }
    
    func loadAudioFile(fileName: String) throws -> URL {
        let fileURL = audioDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(at: fileURL) {
            return fileURL
        } else {
            throw AudioFileError.loadFailed
        }
    }
    
    func deleteAudioFile(fileName: String) throws {
        let fileURL = audioDirectory.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("❌ Error deleting audio file: \(error)")
            throw AudioFileError.deleteFailed
        }
    }
}

private extension FileManager {
    func fileExists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }
} 