import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    // Table definition
    private let tableName = "recordings"
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let fileURL = try FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("recordings.sqlite3")
            
            if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
                print("❌ Error opening database")
                throw DatabaseError.notConnected
            }
            
            let createTableString = """
            CREATE TABLE IF NOT EXISTS \(tableName) (
                id TEXT PRIMARY KEY,
                name TEXT,
                dateCreated REAL,
                duration REAL,
                audioFileName TEXT,
                sourceLanguage TEXT,
                targetLanguage TEXT,
                transcription TEXT,
                translation TEXT
            );
            """
            
            var createTableStatement: OpaquePointer?
            defer { sqlite3_finalize(createTableStatement) }
            
            if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("✅ Recordings table created successfully")
                } else {
                    throw DatabaseError.saveFailed
                }
            } else {
                throw DatabaseError.saveFailed
            }
        } catch {
            print("❌ Database setup failed: \(error)")
        }
    }
    
    func saveRecording(_ recording: RecordingSession) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        
        let insertStatementString = """
        INSERT INTO \(tableName) (
            id, name, dateCreated, duration, audioFileName,
            sourceLanguage, targetLanguage, transcription, translation
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var insertStatement: OpaquePointer?
        defer { sqlite3_finalize(insertStatement) }
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let idString = recording.id.uuidString
            sqlite3_bind_text(insertStatement, 1, (idString as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (recording.name as NSString).utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 3, recording.dateCreated.timeIntervalSince1970)
            sqlite3_bind_double(insertStatement, 4, recording.duration)
            sqlite3_bind_text(insertStatement, 5, (recording.audioFileName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (recording.sourceLanguage as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (recording.targetLanguage as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 8, (recording.transcription as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 9, (recording.translation as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("✅ Recording inserted successfully")
            } else {
                throw DatabaseError.saveFailed
            }
        } else {
            throw DatabaseError.saveFailed
        }
    }
    
    func getAllRecordings(sortBy: RecordingSortOption) throws -> [RecordingSession] {
        guard let db = db else { throw DatabaseError.notConnected }
        
        var recordings: [RecordingSession] = []
        let queryStatementString = "SELECT * FROM \(tableName);"
        var queryStatement: OpaquePointer?
        defer { sqlite3_finalize(queryStatement) }
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(queryStatement, 0),
                      let name = sqlite3_column_text(queryStatement, 1),
                      let audioFileName = sqlite3_column_text(queryStatement, 4),
                      let sourceLanguage = sqlite3_column_text(queryStatement, 5),
                      let targetLanguage = sqlite3_column_text(queryStatement, 6),
                      let transcription = sqlite3_column_text(queryStatement, 7),
                      let translation = sqlite3_column_text(queryStatement, 8),
                      let id = UUID(uuidString: String(cString: idString)) else {
                    continue
                }
                
                let dateCreated = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 2))
                let duration = sqlite3_column_double(queryStatement, 3)
                
                let recording = RecordingSession(
                    id: id,
                    name: String(cString: name),
                    dateCreated: dateCreated,
                    duration: duration,
                    audioFileName: String(cString: audioFileName),
                    sourceLanguage: String(cString: sourceLanguage),
                    targetLanguage: String(cString: targetLanguage),
                    transcription: String(cString: transcription),
                    translation: String(cString: translation)
                )
                recordings.append(recording)
            }
        }
        
        return recordings.sorted(by: sortBy.sortDescriptor)
    }
    
    func deleteRecordingSession(id recordingId: UUID) throws {
        guard let db = db else { throw DatabaseError.notConnected }
        
        let deleteStatementString = "DELETE FROM \(tableName) WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        defer { sqlite3_finalize(deleteStatement) }
        
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            let idString = recordingId.uuidString
            sqlite3_bind_text(deleteStatement, 1, (idString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                throw DatabaseError.deleteFailed
            }
        } else {
            throw DatabaseError.deleteFailed
        }
    }
}

enum DatabaseError: Error {
    case notConnected
    case saveFailed
    case fetchFailed
    case deleteFailed
} 