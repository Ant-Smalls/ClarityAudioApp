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


## 🎙️ Save Recording Flow

**Goal:** Once recording stops, allow the user to save the session into the SQLite database as a named container.

### Steps:

1. After `stopRecording()`, show a **"Save Recording"** button.
2. On click, prompt user to **enter a custom name** (use modal or input dialog).
3. On confirm:
   - Validate name input (not empty).
   - Create a `RecordingContainer` object with:
     - Name
     - Transcription
     - Translation
     - Timestamp
   - Save the container to the **SQLite database**.
4. Refresh the **Library View** so the new container appears immediately.
5. Add **error handling**:
   - Show a message if saving fails.
   - Prevent duplicate or empty names if needed.


   ## 🗣️ Eleven Labs Voice Synthesis Integration

**Goal:** Use Eleven Labs to convert translated text into audio and play it back via a "Play Translation" button.

### Steps:

1. After translation is complete:
   - Send **translated text** to the Eleven Labs API.
   - Set desired **voice ID** (can be default or user-selectable in future).
   - Configure request with appropriate **stability**, **clarity**, and **model** params.

2. On API success:
   - Receive **audio file (MP3 or WAV)** as a response.
   - Store audio in temporary local storage (e.g., cache directory).
   - Set a flag `isAudioReady = true`.

3. In the Record View:
   - Add a **"Play Translation"** button below transcript display.
   - Initially disable the button (`isAudioReady = false`).
   - Once audio is ready, **light up/enable** the button.

4. On button click:
   - Use relevant audio player to **play the audio** file.

5. Add **error handling**:
   - Handle failed API requests gracefully.
   - Optionally show a loading spinner or "Generating audio..." feedback.


   Feature: Clone Your Own Voice Wizard

Goal:
Allow users to clone their voice via ElevenLabs, get a voiceId, and use it as a "Custom" voice option in Clarity’s playback settings.
🎯 Implementation Plan — Safe, Step-by-Step
📦 Phase 1: UI Setup & Flow Structure (No Backend Connection Yet)

    Add a “Clone Your Voice” button in the LanguagesView.

    On press, open a modal or navigate to a VoiceCloneWizardView.

    In this view:

        Offer two options:

            I already have a Voice ID → Text input to enter voiceId.

            Clone a new Voice → Button to open ElevenLabs cloning page via external link.

    Add proper error handling if no Voice ID is provided when selecting Custom voice.

📦 Phase 2: External Cloning Process (User-driven)

    When the user selects Clone a new Voice:

        Open a URL link to ElevenLabs' voice cloning page using Linking.openURL()

            e.g. https://elevenlabs.io/voice-lab

        Include a message:
        "You'll need to log in to ElevenLabs and record a two-minute voice sample to create your voice clone. Once completed, copy your new Voice ID here."

📦 Phase 3: Save Custom Voice ID

    After the user enters a valid Voice ID in the text input:

        Save this value to local storage or SQLite DB under a key like customVoiceId.

        Confirm voiceId validity by optionally hitting the ElevenLabs API to fetch voice details (optional but nice UX check).

        Set this customVoiceId as the third option in your voice picker:

            Male

            Female

            Custom

📦 Phase 4: Integrating Voice ID into Playback

    In your ElevenLabs playback request:

        If the user selects Custom voice:

            Retrieve customVoiceId from storage.

            Use this in the ElevenLabs API request.

            If no customVoiceId exists, show error toast/alert:
            "Please clone your voice or enter your Voice ID before using this feature."

📦 Phase 5 (Optional): Voice ID Management UI

    Add a Manage Voice ID button somewhere in settings:

        Allow users to view, update, or delete their saved customVoiceId.

