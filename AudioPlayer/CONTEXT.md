## Features to Implement & Improvements

### 1. 📁 Database Integration
**Objective:** Store and organize saved transcription+translation sessions locally.

#### Tasks:
- Integrate **SQLite** with the project.
- Create a **RecordingContainer** model to hold:
  - Original audio filename
  - Transcript
  - Translated text
  - Timestamp
  - Custom user-defined name
- Implement **CRUD functionality**:
  - Save new containers
  - Delete containers
  - Rename containers
- Build a **Library view page** to show saved containers in a scrollable list.

### Database Implementation Phases

#### Phase 1: Basic Setup & Model Creation
- Set up SQLite integration
- Create RecordingSession model with:
  ```swift
  struct RecordingSession {
      let id: UUID
      let name: String
      let dateCreated: Date
      let duration: TimeInterval
      let audioFileName: String
      let sourceLanguage: String
      let targetLanguage: String
      let transcription: String
      let translation: String
  }
  ```
- Create DatabaseManager singleton
- Test: Verify database connection and table creation

#### Phase 2: Basic CRUD Operations
- Implement core database operations:
  - Create: Save new recording session
  - Read: Fetch single session by ID
  - Update: Update session name
  - Delete: Remove session and associated audio
- Create AudioFileManager for handling audio files
- Test: Verify each CRUD operation individually

#### Phase 3: Library View Integration
- Create basic Library view 
- Implement fetch all recordings functionality
- Add sorting (by date, name)
- Display recordings in list format
- Test: Verify UI displays database contents correctly

#### Phase 4: Recording Integration
- Modify RecordView to save sessions after translation
- Connect audio file saving with database entry
- Implement proper error handling
- Test: Complete recording-to-library workflow

#### Phase 5: Advanced Features
- Add search functionality
- Implement batch operations (delete multiple)
- Add recording categories/tags
- Add recording favorites
- Test: Verify all features with various data sets

#### Testing Checkpoints
After each phase:
1. Database integrity
2. Data persistence across app restarts
3. Audio file management
4. Memory management
5. Error handling
6. UI responsiveness
7. Edge cases (empty states, large datasets)

#### Rollback Plan
- Create backup methods for database
- Implement data migration strategies
- Plan for schema updates

---

### 2. 🗣️ Transcription Process
**Objective:** Improve usability by eliminating the need to manually select the input language.

#### Tasks:
- Use **language auto-detection** in the transcription API or integrate a separate auto-detect model pre-call.
- Fallback to user-selected language if auto-detection fails or confidence score is low.

---

### 3. 🌍 Translation Process
**Objective:** Add support for Serbian if possible.

#### Tasks:
- Check if Apple's translation API or the current translation provider supports Serbian.

---

### 4. 🧭 UI Navigation
**Objective:** Make the app intuitive and polished with clear navigation.

#### Tasks:
- Implement a **bottom tab navigation** system with 3 pages:
  - 🌐 Languages page (icon: globe)
  - 🎙️ Record page (icon: microphone)
  - 📚 Library page (icon: book or folder)
- Each page should be clearly separated and maintainable in its own view file.

---

### 5. 🧹 Project Cleanup
**Objective:** Improve file organization and maintainability.

#### Tasks:
- Organize files into clean folders:
  - `views/` – all screen components (Record, Library, Languages)
  - `models/` – data models (e.g., RecordingContainer)
  - `database/` – SQLite setup and utility functions
  - `assets/` – icons, images, and static content
  - `components/` – reusable UI elements like buttons, cards
- Rename files for clarity and consistent naming conventions.
- Document components with JSDoc or comments for clarity.

---

## Implementation Plan (Suggested Order)

1. **Project Cleanup** – clean file structure first to avoid tech debt.
2. **Add SQLite and Models** – build the data model and database logic.
3. **Create Library Page** – implement UI for browsing saved sessions.
4. **Add CRUD Functionality** – wire save/delete/rename to database.
5. **Integrate Language Auto-Detection** – improve the transcription flow.
6. **Update UI with Bottom Tabs** – connect 3-page navigation.
7. **Check & Add Serbian Translation Support** – fallback if unsupported.