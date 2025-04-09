//
//  ViewController.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 12/6/24.

import UIKit
import AVFoundation
import Speech
import SwiftUI

class ViewController: UIViewController, AVAudioRecorderDelegate, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate {
    
    // MARK: - Properties
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var isRecording = false
    var audioFileName: URL?
    var recordingCount = 1
    var recordedFiles: [URL] = []
    
    // Dynamic language selections.
    var inputLanguage: String = "en-US" {
        didSet {
            updateSpeechRecognizer()
        }
    }
    var outputLanguage: String = "es-ES" {
        didSet {
            // Update UI or state if needed
        }
    }
    
    var finalTranscriptionText: String = ""
    var finalTranslatedText: String = ""
    
    var speechRecognizer: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var speechSynthesizer = AVSpeechSynthesizer()
    var speechSynthesizerDelegate: SpeechSynthesizerDelegate?
    var translationAudioQueue: [URL] = []
    
    var elevenLabsAudioFileURL: URL?
    
    // Gradient layer property.
    var gradientLayer: CAGradientLayer?
    
    private var recordingStartTime: Date?
    private var currentRecordingURL: URL?
    
    // Add language pairs support
    private let supportedInputLanguages = [
        "en-US": "English (US)",
        "es-ES": "Spanish (Spain)",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian"
    ]
    
    private let supportedOutputLanguages = [
        "en-US": "English (US)",
        "es-ES": "Spanish (Spain)",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian"
    ]
    
    // MARK: - UI Elements (Connected via Storyboard)
    @IBOutlet weak var recordButton: UIButton?
    @IBOutlet weak var stopRecordButton: UIButton?
    @IBOutlet weak var transcriptionTextView: UITextView?
    @IBOutlet weak var translationTextView: UITextView?
    @IBOutlet weak var playTranslatedAudioButton: UIButton?
    
    // MARK: - Lifecycle Methods
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyGradientBackground()
        setupAudioSession()
        requestSpeechPermission()
        styleUI()
        
        // Set initial button states.
        recordButton?.alpha = 1
        stopRecordButton?.alpha = 0
        
        print("✅ Using Input Language: \(inputLanguage), Output Language: \(outputLanguage)")
        
        updateSpeechRecognizer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the gradient layer covers the entire view.
        gradientLayer?.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ ViewController appeared successfully!")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("⚠️ ViewController is disappearing, cleaning up translation tasks.")
        
        // Remove any embedded SwiftUI TranslationView.
        for child in children {
            if let hostingController = child as? UIHostingController<TranslationView> {
                hostingController.willMove(toParent: nil)
                hostingController.view.removeFromSuperview()
                hostingController.removeFromParent()
            }
        }
        self.finalTranslatedText = ""
    }
    
    // MARK: - Gradient Background Setup
    func applyGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            AppTheme.backgroundColorUI.cgColor,
            AppTheme.secondaryColorUI.cgColor,
            AppTheme.accentColorUI.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    // MARK: - UI Styling
    func styleUI() {
        guard let recordButton = recordButton,
              let stopRecordButton = stopRecordButton,
              let playTranslatedAudioButton = playTranslatedAudioButton,
              let transcriptionTextView = transcriptionTextView,
              let translationTextView = translationTextView else {
            print("❌ One or more UI elements not connected in storyboard")
            return
        }
        
        // Set a modern, clean font for buttons.
        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        recordButton.titleLabel?.font = buttonFont
        stopRecordButton.titleLabel?.font = buttonFont
        playTranslatedAudioButton.titleLabel?.font = buttonFont
        
        // Style record button.
        recordButton.backgroundColor = AppTheme.secondaryColorUI
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 8
        
        // Style stop record button.
        stopRecordButton.backgroundColor = AppTheme.secondaryColorUI
        stopRecordButton.setTitleColor(.white, for: .normal)
        stopRecordButton.layer.cornerRadius = 8
        
        // Style play translated audio button.
        playTranslatedAudioButton.backgroundColor = AppTheme.secondaryColorUI
        playTranslatedAudioButton.setTitleColor(.white, for: .normal)
        playTranslatedAudioButton.layer.cornerRadius = 8
        
        // Style transcription text view.
        transcriptionTextView.backgroundColor = AppTheme.accentColorUI
        transcriptionTextView.textColor = .white
        transcriptionTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        transcriptionTextView.layer.cornerRadius = 8
        transcriptionTextView.clipsToBounds = true
        
        // Style translation text view.
        translationTextView.backgroundColor = AppTheme.accentColorUI
        translationTextView.textColor = .white
        translationTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        translationTextView.layer.cornerRadius = 8
        translationTextView.clipsToBounds = true
    }
    
    // MARK: - Speech Recognition Setup
    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized.")
                    self.recordButton?.isEnabled = true
                case .denied:
                    print("❌ User denied speech recognition.")
                    self.recordButton?.isEnabled = false
                case .restricted, .notDetermined:
                    print("❌ Speech recognition not available.")
                    self.recordButton?.isEnabled = false
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Recording Setup
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
    
    // MARK: - Recording Actions
    @IBAction func handleRecord() {
        if !audioEngine.isRunning {
            guard setupAudioRecorder() else {
                print("❌ Failed to setup audio recorder")
                return
            }
            
            recordingStartTime = Date()
            audioRecorder?.record()
            startRealTimeTranscription()
            
            UIView.animate(withDuration: 0.3) {
                self.recordButton?.alpha = 0
                self.stopRecordButton?.alpha = 1
            }
        }
    }
    
    @IBAction func handleStopRecording() {
        print("🛑 Stopping Recording...")
        
        // Stop audio recording
        audioRecorder?.stop()
        
        // Store final transcription
        let finalText = self.transcriptionTextView?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if finalText.isEmpty {
            print("⚠️ Ignoring empty final transcription. Nothing to translate.")
            cleanupRecording()
            return
        }
        
        self.finalTranscriptionText = finalText
        
        // Present translation view and save recording when translation is complete
        self.presentTranslationView(with: finalText)
        
        // Clean up audio engine
        cleanupRecording()
        
        UIView.animate(withDuration: 0.3) {
            self.recordButton?.alpha = 1
            self.stopRecordButton?.alpha = 0
        }
    }
    
    private func cleanupRecording() {
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
        self.recognitionRequest = nil
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.audioEngine.stop()
        self.speechRecognizer = nil
    }
    
    // MARK: - AVAudioRecorderDelegate
    @objc func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("❌ Recording failed")
            cleanupRecording()
        }
    }
    
    func startRealTimeTranscription() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: inputLanguage))
        guard let speechRecognizer = speechRecognizer else {
            print("❌ Speech recognizer not available for language: \(inputLanguage)")
            
            // Show error alert to user
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Language Not Supported",
                    message: "Speech recognition is not available for the selected input language: \(self.supportedInputLanguages[self.inputLanguage] ?? self.inputLanguage)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
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
            print("🎤 Audio engine started for transcription.")
        } catch {
            print("❌ Failed to start audio engine:", error)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                print("📝 Transcribed: \(transcribedText)")
                
                if self.recognitionTask == nil {
                    print("⚠️ Skipping translation: Recognition was canceled.")
                    return
                }
                
                DispatchQueue.main.async {
                    self.transcriptionTextView?.text = transcribedText
                }
            }
            
            if let error = error as NSError? {
                if error.code == 1110 {
                    print("⚠️ Ignoring 'No speech detected' error (User stopped speaking).")
                    return
                } else if error.code == 301 {
                    print("⚠️ Ignoring 'Recognition request was canceled' error (User stopped recording).")
                    return
                }
                print("❌ Transcription error: \(error.localizedDescription) \(error.code)")
            }
        }
    }
    
    // MARK: - Translation Integration
    func presentTranslationView(with text: String) {
        // Convert language codes to simple format
        let sourceLanguage = inputLanguage.components(separatedBy: "-").first ?? "en"
        let targetLanguage = outputLanguage.components(separatedBy: "-").first ?? "es"
        
        let translationView = TranslationView(
            sourceText: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            onComplete: { [weak self] translatedText in
                guard let self = self else { return }
                
                self.finalTranslatedText = translatedText
                self.translationTextView?.text = translatedText
                
                // Save the recording session
                if let audioURL = self.currentRecordingURL {
                    self.saveRecordingSession(
                        transcription: self.finalTranscriptionText,
                        translation: translatedText,
                        audioURL: audioURL
                    )
                }
                
                // Generate audio for the translation
                self.generateAudioFromTranslation(translatedText)
            }
        )
        
        let hostingController = UIHostingController(rootView: translationView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }
    
    // MARK: - Save Recording
    private func saveRecordingSession(transcription: String, translation: String, audioURL: URL) {
        guard let startTime = recordingStartTime else {
            print("❌ No recording start time available")
            return
        }
        
        do {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime)
            
            // Save audio file
            let fileName = try AudioFileManager.shared.saveAudioFile(sourceURL: audioURL, withName: "Recording")
            
            // Create recording session
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
            
            // Save to database
            try DatabaseManager.shared.saveRecordingSession(session)
            print("✅ Recording saved successfully")
            
        } catch {
            print("❌ Error saving recording: \(error)")
            // Show error alert
            let alert = UIAlertController(
                title: "Error",
                message: "Failed to save recording: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    // MARK: - Audio Generation & Playback
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func generateAudioFromTranslation(_ text: String) {
        print("🔊 Generating audio from translated text (FINAL).")
        
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: outputLanguage)
        
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let fileURL = getDocumentsDirectory().appendingPathComponent("translatedSpeech_\(timestamp).m4a")
        
        self.elevenLabsAudioFileURL = fileURL
        print("✅ Saving translated speech to: \(fileURL)")
        
        speechSynthesizerDelegate = SpeechSynthesizerDelegate(completion: {
            DispatchQueue.main.async {
                print("✅ Finished Playing Translated Audio")
            }
        })
        
        speechSynthesizer.delegate = speechSynthesizerDelegate
        speechSynthesizer.speak(speechUtterance)
        
        DispatchQueue.main.async {
            self.playTranslatedAudioButton?.isEnabled = true
        }
    }
    
    @IBAction func handlePlayTranslatedAudio() {
        guard let audioFileURL = elevenLabsAudioFileURL else {
            print("⚠️ No translated audio file available to play.")
            return
        }
        
        guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
            print("❌ Translated audio file is missing: \(audioFileURL.path)")
            return
        }
        
        do {
            setupAudioSession()
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("✅ Playing translated audio.")
        } catch {
            print("❌ Failed to play translated audio:", error)
        }
    }
    
    // MARK: - Language Handling
    private func updateSpeechRecognizer() {
        // Stop any ongoing recognition
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Create new speech recognizer with updated language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: inputLanguage))
        
        // Request authorization if needed
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("✅ Speech recognition authorized for language: \(self.inputLanguage)")
                case .denied:
                    self.showSpeechRecognitionAlert(message: "Speech recognition permission was denied.")
                case .restricted:
                    self.showSpeechRecognitionAlert(message: "Speech recognition is restricted on this device.")
                case .notDetermined:
                    self.showSpeechRecognitionAlert(message: "Speech recognition not yet authorized.")
                @unknown default:
                    self.showSpeechRecognitionAlert(message: "Speech recognition status unknown.")
                }
            }
        }
    }
    
    private func showSpeechRecognitionAlert(message: String) {
        let alert = UIAlertController(
            title: "Speech Recognition Status",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SpeechSynthesizerDelegate
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let completion: () -> Void
    init(completion: @escaping () -> Void) { self.completion = completion }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion()
    }
}
