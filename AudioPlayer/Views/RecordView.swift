import SwiftUI
import AVFoundation
import Speech

struct RecordView: View {
    @StateObject var viewModel: RecordViewModel
    
    init(inputLanguage: String = "en-US", outputLanguage: String = "es-ES") {
        let model = RecordViewModel()
        model.inputLanguage = inputLanguage
        model.outputLanguage = outputLanguage
        _viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    AppTheme.secondaryColor,
                    AppTheme.accentColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Transcription Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transcriptions:")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    TextEditor(text: .constant(viewModel.transcriptionText))
                        .frame(height: 200)
                        .background(AppTheme.accentColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Translation Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Translations:")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    TextEditor(text: .constant(viewModel.translationText))
                        .frame(height: 200)
                        .background(AppTheme.accentColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Spacer()
                
                // Record Button
                Button(action: {
                    viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                }) {
                    Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.secondaryColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Play Translated Audio Button
                Button(action: {
                    viewModel.playTranslatedAudio()
                }) {
                    Text("Play Translated Audio")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.secondaryColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(!viewModel.hasTranslatedAudio)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
        }
    }
}

class RecordViewModel: NSObject, ObservableObject {
    @Published var transcriptionText: String = ""
    @Published var translationText: String = ""
    @Published var isRecording: Bool = false
    @Published var hasTranslatedAudio: Bool = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var currentRecordingURL: URL?
    private var recordingStartTime: Date?
    
    var inputLanguage: String = "en-US"
    var outputLanguage: String = "es-ES"
    
    override init() {
        super.init()
        setupAudioSession()
        requestSpeechPermission()
        updateSpeechRecognizer()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized.")
                default:
                    print("❌ Speech recognition not available.")
                }
            }
        }
    }
    
    private func updateSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: inputLanguage))
    }
    
    private func setupAudioRecorder() -> Bool {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        currentRecordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            return true
        } catch {
            print("❌ Failed to setup audio recorder: \(error)")
            return false
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        guard setupAudioRecorder() else {
            print("❌ Failed to setup audio recorder")
            return
        }
        
        recordingStartTime = Date()
        audioRecorder?.record()
        startRealTimeTranscription()
        isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        
        let finalText = transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalText.isEmpty {
            translateText(finalText)
        }
        
        cleanupRecording()
        isRecording = false
    }
    
    private func cleanupRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    private func startRealTimeTranscription() {
        guard let speechRecognizer = speechRecognizer else {
            print("❌ Speech recognizer not available")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ Failed to start audio engine:", error)
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcriptionText = transcribedText
                }
            }
            
            if let error = error as NSError? {
                if error.code == 1110 || error.code == 301 {
                    // Ignore "no speech detected" and "canceled" errors
                    return
                }
                print("❌ Recognition error: \(error)")
            }
        }
    }
    
    private func translateText(_ text: String) {
        // Convert language codes to simple format
        let sourceLanguage = inputLanguage.components(separatedBy: "-").first ?? "en"
        let targetLanguage = outputLanguage.components(separatedBy: "-").first ?? "es"
        
        // Create translation view
        let translationView = TranslationView(
            sourceText: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        ) { [weak self] translatedText in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.translationText = translatedText
                self.hasTranslatedAudio = true
                
                // Save recording session
                if let audioURL = self.currentRecordingURL {
                    self.saveRecordingSession(
                        transcription: text,
                        translation: translatedText,
                        audioURL: audioURL
                    )
                }
                
                // Generate audio for translation
                self.generateAudioFromTranslation(translatedText)
            }
        }
    }
    
    private func generateAudioFromTranslation(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: outputLanguage)
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func playTranslatedAudio() {
        // Play the translated audio using AVSpeechSynthesizer
        let utterance = AVSpeechUtterance(string: translationText)
        utterance.voice = AVSpeechSynthesisVoice(language: outputLanguage)
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    private func saveRecordingSession(transcription: String, translation: String, audioURL: URL) {
        guard let startTime = recordingStartTime else { return }
        
        do {
            let duration = Date().timeIntervalSince(startTime)
            let fileName = try AudioFileManager.shared.saveAudioFile(sourceURL: audioURL, withName: "Recording")
            
            let session = RecordingSession(
                name: "Recording \(DateFormatter.localizedString(from: startTime, dateStyle: .none, timeStyle: .short))",
                dateCreated: startTime,
                duration: duration,
                audioFileName: fileName,
                sourceLanguage: inputLanguage,
                targetLanguage: outputLanguage,
                transcription: transcription,
                translation: translation
            )
            
            try DatabaseManager.shared.saveRecordingSession(session)
            print("✅ Recording saved successfully")
        } catch {
            print("❌ Error saving recording: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension RecordViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("❌ Recording failed")
            cleanupRecording()
        }
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView()
    }
} 