import Foundation
import SQLite3

enum DatabaseError: Error {
    case connectionFailed
    case prepareFailed
    case insertFailed
    case queryFailed
    case deleteFailed
    case updateFailed
}

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recordings.sqlite")
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            createTables()
            print("✅ Successfully opened database at \(fileURL.path)")
        } else {
            print("❌ Error opening database")
        }
    }
    
    private func createTables() {
        let createTableQuery = """
            CREATE TABLE IF NOT EXISTS recording_sessions (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                date_created INTEGER NOT NULL,
                duration REAL NOT NULL,
                audio_file_name TEXT NOT NULL,
                source_language TEXT NOT NULL,
                target_language TEXT NOT NULL,
                transcription TEXT NOT NULL,
                translation TEXT NOT NULL
            );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ Recording sessions table created successfully")
            } else {
                print("❌ Error creating table")
            }
        } else {
            print("❌ Error preparing create table statement")
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - CRUD Operations
    
    func saveRecordingSession(_ session: RecordingSession) throws {
        let insertQuery = """
            INSERT INTO recording_sessions (
                id, name, date_created, duration, audio_file_name,
                source_language, target_language, transcription, translation
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (session.id as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (session.name as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 3, Int64(session.dateCreated.timeIntervalSince1970))
        sqlite3_bind_double(statement, 4, session.duration)
        sqlite3_bind_text(statement, 5, (session.audioFileName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 6, (session.sourceLanguage as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 7, (session.targetLanguage as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 8, (session.transcription as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 9, (session.translation as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.insertFailed
        }
        
        print("✅ Recording session saved successfully")
    }
    
    func getAllRecordingSessions() throws -> [RecordingSession] {
        let query = "SELECT * FROM recording_sessions ORDER BY date_created DESC;"
        var statement: OpaquePointer?
        var sessions: [RecordingSession] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let name = String(cString: sqlite3_column_text(statement, 1))
            let dateCreated = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 2)))
            let duration = sqlite3_column_double(statement, 3)
            let audioFileName = String(cString: sqlite3_column_text(statement, 4))
            let sourceLanguage = String(cString: sqlite3_column_text(statement, 5))
            let targetLanguage = String(cString: sqlite3_column_text(statement, 6))
            let transcription = String(cString: sqlite3_column_text(statement, 7))
            let translation = String(cString: sqlite3_column_text(statement, 8))
            
            let session = RecordingSession(
                id: id,
                name: name,
                dateCreated: dateCreated,
                duration: duration,
                audioFileName: audioFileName,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                transcription: transcription,
                translation: translation
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    func deleteRecordingSession(id: String) throws {
        let query = "DELETE FROM recording_sessions WHERE id = ?;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.deleteFailed
        }
        
        print("✅ Recording session deleted successfully")
    }
    
    func updateRecordingSession(_ session: RecordingSession) throws {
        let updateQuery = """
            UPDATE recording_sessions
            SET name = ?, date_created = ?, duration = ?, audio_file_name = ?,
                source_language = ?, target_language = ?, transcription = ?, translation = ?
            WHERE id = ?;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (session.name as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 2, Int64(session.dateCreated.timeIntervalSince1970))
        sqlite3_bind_double(statement, 3, session.duration)
        sqlite3_bind_text(statement, 4, (session.audioFileName as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 5, (session.sourceLanguage as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 6, (session.targetLanguage as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 7, (session.transcription as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 8, (session.translation as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 9, (session.id as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.updateFailed
        }
        
        print("✅ Recording session updated successfully")
    }
} 