//
//  ViewController.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 12/6/24.

import UIKit
import AVFoundation
import Speech
import Translation
import SwiftUI
import Foundation

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate {
    
    // MARK: - Properties
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var isRecording = false
    var audioFileName: URL?
    var recordingCount = 1
    var recordedFiles: [URL] = []
    
    // Dynamic language selections.
    var inputLanguage: String = UserDefaults.standard.string(forKey: "selectedInputLanguage") ?? "en-US"
    var outputLanguage: String = UserDefaults.standard.string(forKey: "selectedOutputLanguage") ?? "es"
    var finalTranscriptionText: String = ""
    var finalTranslatedText: String = ""
    
    // Language display names
    private let languageDisplayNames: [String: String] = [
        "en": "English",
        "es": "Spanish",
        "de": "German",
        "pt": "Portuguese",
        "ja": "Japanese",
        "fr": "French",
        "it": "Italian",
        "ru": "Russian",
        "ko": "Korean"
    ]
    
    // Language indicator label
    private var languageIndicatorLabel: UILabel!
    
    // Add language switch button
    private var languageSwitchButton: UIButton!
    
    var speechRecognizer: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var translationAudioQueue: [URL] = []
    
    var elevenLabsAudioFileURL: URL?
    
    // Gradient layer property.
    var gradientLayer: CAGradientLayer?
    
    // Add new properties
    private var currentRecordingDuration: TimeInterval = 0
    private var recordingStartTime: Date?
    
    // Add currentRecording property
    private var currentRecording: RecordingSession?
    
    // Add voice IDs for each language and gender
    private struct VoiceID {
        let male: String
        let female: String
    }
    
    private let languageVoiceIds: [String: VoiceID] = [
        "en-US": VoiceID(
            male: "NOpBlnGInO9m6vDvFkFC", // good
            female: "kdmDKE6EkgrWrrykO9Qt" // good
        ),
        "es": VoiceID(
            male: "aAtR3uAVlEaQIWGd9EDO", // good
            female: "br0MPoLVxuslVxf61qHn" // good
        ),
        "de": VoiceID(
            male: "5euSC8RarC3AHrZ242sr", // good
            female: "yUy9CCX9brt8aPVvIWy3" // bad
        ),
        "pt-BR": VoiceID(
            male: "7u8qsX4HQsSHJ0f8xsQZ", // ok
            female: "cyD08lEy76q03ER1jZ7y" // ok
        ),
        "ja": VoiceID(
            male: "3JDquces8E8bkmvbh6Bc", // i think this is good, ask Yusuke?
            female: "8EkOjt4xTPGMclNlh1pk" // bad
        ),
        "fr": VoiceID(
            male: "RTFg9niKcgGLDwa3RFlz", // bad
            female: "WQKwBV2Uzw1gSGr69N8I" // ok
        ),
        "it": VoiceID(
            male: "uScy1bXtKz8vPzfdFsFw", // ok
            female: "201hPjDVu4Q5DUV7tMQJ" // ok
        ),
        "ru": VoiceID(
            male: "3EuKHIEZbSzrHGNmdYsx", // ok
            female: "tOo2BJ74frmnPadsDNIi" // good
        ),
        "ko": VoiceID(
            male: "FQ3MuLxZh0jHcZmA5vW1", // bad
            female: "uyVNoMrnUku1dZyVEXwD" // Using male voice as fallback for Korean
        )
    ]
    
    // Add selected gender property
    private var selectedGender: String = UserDefaults.standard.string(forKey: "selectedVoiceGender") ?? "male"
    
    // Add property for language detection state
    private var isLanguageDetectionEnabled: Bool = UserDefaults.standard.bool(forKey: "isLanguageDetectionEnabled")
    
    // MARK: - UI Elements (Connected via Storyboard)
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var translationTextView: UITextView!
    @IBOutlet weak var playTranslatedAudioButton: UIButton!
    
    // Remove IBOutlet and make it a regular property
    private var saveRecordingButton: UIButton!
    private var playTranslationButton: UIButton!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        applyGradientBackground()
        setupAudioSession()
        requestSpeechPermission()
        setupSaveButton()
        setupPlayButton()
        styleUI()
        
        // Set initial button states.
        recordButton.alpha = 1
        stopRecordButton.alpha = 0
        saveRecordingButton.isHidden = true
        playTranslatedAudioButton.isHidden = true
        
        print("✅ Using Input Language: \(inputLanguage), Output Language: \(outputLanguage)")
        
        // Add observer for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageSelection),
            name: Notification.Name("LanguagesSelected"),
            object: nil
        )
        
        setupDetectionStatusLabel()
        
        // Add observer for language detection toggle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageDetectionToggle),
            name: Notification.Name("LanguageDetectionToggled"),
            object: nil
        )
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
            UIColor(hex: "#23252c").cgColor,
            UIColor(hex: "#40607e").cgColor,
            UIColor(hex: "#584d78").cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    // MARK: - UI Styling
    func styleUI() {
        // Style record button - make it circular with just the mic icon
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.backgroundColor = .white
        recordButton.tintColor = UIColor(hex: "#40607e")
        recordButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        recordButton.setTitle("", for: .normal) // Remove text, icon only
        recordButton.layer.cornerRadius = 40 // Increased from 30 to 40
        recordButton.clipsToBounds = true
        
        // Add shadow to record button
        recordButton.layer.shadowColor = UIColor.black.cgColor
        recordButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        recordButton.layer.shadowRadius = 4
        recordButton.layer.shadowOpacity = 0.2
        recordButton.layer.masksToBounds = false
        
        // Style stop record button - make it circular with stop icon
        stopRecordButton.translatesAutoresizingMaskIntoConstraints = false
        stopRecordButton.backgroundColor = UIColor(hex: "#FF3B30")
        stopRecordButton.tintColor = .white
        stopRecordButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopRecordButton.setTitle("", for: .normal) // Remove text, icon only
        stopRecordButton.layer.cornerRadius = 40 // Increased from 30 to 40
        stopRecordButton.clipsToBounds = true
        
        // Add shadow to stop button
        stopRecordButton.layer.shadowColor = UIColor.black.cgColor
        stopRecordButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        stopRecordButton.layer.shadowRadius = 4
        stopRecordButton.layer.shadowOpacity = 0.2
        stopRecordButton.layer.masksToBounds = false
        
        // Update button constraints to center them and prevent overlapping
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -140),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            stopRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopRecordButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            stopRecordButton.widthAnchor.constraint(equalToConstant: 80),
            stopRecordButton.heightAnchor.constraint(equalToConstant: 80),
        ])
        
        // Style text views
        transcriptionTextView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        transcriptionTextView.textColor = .white
        transcriptionTextView.font = .systemFont(ofSize: 16, weight: .regular)
        transcriptionTextView.layer.cornerRadius = 12
        transcriptionTextView.clipsToBounds = true
        transcriptionTextView.isEditable = false
        
        translationTextView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        translationTextView.textColor = .white
        translationTextView.font = .systemFont(ofSize: 16, weight: .regular)
        translationTextView.layer.cornerRadius = 12
        translationTextView.clipsToBounds = true
        translationTextView.isEditable = false
        
        // Remove old language indicator setup and constraints
        setupLanguageIndicator()
        
        // Adjust save button position to be below record/stop buttons
        NSLayoutConstraint.activate([
            saveRecordingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            saveRecordingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            saveRecordingButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 16),
            saveRecordingButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupLanguageIndicator() {
        // Create stack view to hold label and switch button
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        view.addSubview(stackView)
        
        // Setup language indicator label
        languageIndicatorLabel = UILabel()
        languageIndicatorLabel.textColor = .white
        languageIndicatorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        languageIndicatorLabel.textAlignment = .center
        
        // Setup switch button
        languageSwitchButton = UIButton(type: .system)
        languageSwitchButton.setImage(UIImage(systemName: "arrow.left.arrow.right"), for: .normal)
        languageSwitchButton.tintColor = .white
        languageSwitchButton.addTarget(self, action: #selector(handleLanguageSwitch), for: .touchUpInside)
        
        // Add both to stack view
        stackView.addArrangedSubview(languageIndicatorLabel)
        stackView.addArrangedSubview(languageSwitchButton)
        
        // Add constraints for stack view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: transcriptionTextView.bottomAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: translationTextView.topAnchor, constant: -8)
        ])
        
        updateLanguageIndicator()
    }
    
    @objc private func handleLanguageSwitch() {
        // Add quick rotation animation to the switch button
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
            self.languageSwitchButton.transform = self.languageSwitchButton.transform.rotated(by: .pi)
        }
        
        // First, clean up any existing audio session and resources
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Deactivate and reactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            
            // Reset audio session category
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, 
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            
            // Set preferred sample rate and I/O buffer duration
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44100.0)
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
        } catch {
            print("❌ Failed to reset audio session: \(error)")
        }
        
        // Swap languages
        let tempLang = inputLanguage
        inputLanguage = outputLanguage
        outputLanguage = tempLang
        
        // Save the swapped languages to UserDefaults
        UserDefaults.standard.set(inputLanguage, forKey: "selectedInputLanguage")
        UserDefaults.standard.set(outputLanguage, forKey: "selectedOutputLanguage")
        UserDefaults.standard.synchronize()
        
        // Update UI
        updateLanguageIndicator()
        
        // Post notification for language change
        let userInfo: [String: String] = [
            "inputLanguage": inputLanguage,
            "outputLanguage": outputLanguage
        ]
        NotificationCenter.default.post(
            name: Notification.Name("LanguagesSelected"),
            object: nil,
            userInfo: userInfo
        )
        
        // Initialize new speech recognizer for the new language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: inputLanguage))
        
        // Reset text views
        transcriptionTextView.text = ""
        translationTextView.text = ""
    }
    
    private func updateLanguageIndicator() {
        let inputName = languageDisplayNames[inputLanguage.split(separator: "-").first?.description ?? inputLanguage] ?? inputLanguage
        let outputName = languageDisplayNames[outputLanguage.split(separator: "-").first?.description ?? outputLanguage] ?? outputLanguage
        languageIndicatorLabel.text = "\(inputName) → \(outputName)"
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
    
    // MARK: - Recording Actions
    @IBAction func handleRecord() {
        if !audioEngine.isRunning {
            // Clear text views before starting new recording
            transcriptionTextView.text = ""
            translationTextView.text = ""
            
            // Reset audio engine and configuration
            audioEngine.stop()
            audioEngine.reset()
            
            // Remove any existing tap
            if audioEngine.inputNode.numberOfInputs > 0 {
                audioEngine.inputNode.removeTap(onBus: 0)
            }
            
            // Reset audio session
            do {
                try AVAudioSession.sharedInstance().setActive(false)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, 
                    mode: .measurement,
                    options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("❌ Failed to reset audio session: \(error)")
                return
            }
            
            startRealTimeTranscription()
            recordingStartTime = Date()
            UIView.animate(withDuration: 0.3) {
                self.recordButton.alpha = 0
                self.stopRecordButton.alpha = 1
                // Hide both buttons during recording
                self.saveRecordingButton.isHidden = true
                self.playTranslationButton.isHidden = true
            }
        }
    }
    
    @IBAction func handleStopRecording() {
        print("🛑 Stopping Recording...")
        
        if let startTime = recordingStartTime {
            currentRecordingDuration = Date().timeIntervalSince(startTime)
        }
        
        // Detach the speech recognizer.
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
        self.recognitionRequest = nil
        
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.audioEngine.stop()
        self.speechRecognizer = nil
        
        let finalText = self.transcriptionTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Always reset UI state first
        UIView.animate(withDuration: 0.3) {
            self.recordButton.alpha = 1
            self.stopRecordButton.alpha = 0
        }
        
        if finalText.isEmpty {
            print("⚠️ No transcription detected.")
            // Show a user-friendly message
            let alert = UIAlertController(
                title: "No Speech Detected",
                message: "No speech was detected during the recording. Would you like to try again?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
                // Reset the text views
                self.transcriptionTextView.text = ""
                self.translationTextView.text = ""
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
            return
        }
        
        print("🌍 Finalizing translation for: \(finalText)")
        self.finalTranscriptionText = finalText
        self.presentTranslationView(with: finalText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.finalTranslatedText.isEmpty {
                self.generateAudioFromTranslation(self.finalTranslatedText)
                // Show both buttons after translation is ready
                self.saveRecordingButton.isHidden = false
                self.playTranslationButton.isHidden = false
            } else {
                print("⚠️ No translated text available for audio generation.")
            }
        }
        
        // Hide detection status label when stopping
        detectionStatusLabel.isHidden = true
    }
    
    func startRealTimeTranscription() {
        // Initialize speech recognizer with current input language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: inputLanguage))
        guard let speechRecognizer = speechRecognizer else {
            print("❌ Speech recognizer not available for language: \(inputLanguage)")
            showAlert(title: "Error", message: "Speech recognition is not available for \(languageDisplayNames[inputLanguage] ?? inputLanguage)")
            return
        }
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio session
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0,
                           bufferSize: 1024,
                           format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcriptionTextView.text = transcribedText
                    
                    // Only perform language detection if enabled
                    if self.isLanguageDetectionEnabled && transcribedText.split(separator: " ").count >= 3 {
                        self.languageDetectionViewModel.processTranscription(transcribedText)
                        if let detectedLanguage = self.languageDetectionViewModel.detectedLanguage {
                            self.updateDetectionStatus(with: detectedLanguage.name)
                            
                            // Only show language mismatch alert if detection is enabled
                            if detectedLanguage.code != self.inputLanguage.split(separator: "-").first?.description {
                                self.showLanguageMismatchAlert(detectedLanguage: detectedLanguage.name)
                            }
                        }
                    }
                    
                    // Update translation in real-time
                    if !transcribedText.isEmpty {
                        self.presentTranslationView(with: transcribedText)
                    }
                }
            }
            
            if error != nil {
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
                self.detectionStatusLabel.isHidden = true
            }
        }
        
        // Prepare and start audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("❌ Audio engine failed to start: \(error)")
        }
    }
    
    // MARK: - Translation Integration
    func presentTranslationView(with text: String) {
        guard self.isViewLoaded && self.view.window != nil else {
            print("⚠️ Skipping translation: ViewController is disappearing.")
            return
        }
        
        let swiftUIView = TranslationView(
            textToTranslate: text,
            sourceLanguage: Locale.Language(identifier: inputLanguage),
            targetLanguage: Locale.Language(identifier: outputLanguage)
        ) { translatedText in
            DispatchQueue.main.async {
                print("✅ Translated: \(translatedText)")
                self.finalTranscriptionText = text
                self.finalTranslatedText = translatedText
                self.transcriptionTextView.text = text
                self.translationTextView.text = translatedText
            }
        }
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        // Hide the hosting controller completely.
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        hostingController.view.isHidden = true
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Audio Generation & Playback
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func generateAudioFromTranslation(_ text: String) {
        print("🔊 Generating audio from translated text (FINAL).")
        
        // Disable button while processing
        playTranslationButton.isEnabled = false
        
        Task {
            do {
                // Show loading state
                DispatchQueue.main.async {
                    self.playTranslationButton.setTitle("Generating...", for: .normal)
                }
                
                // Get the appropriate voice ID for the output language and gender
                let voiceData = languageVoiceIds[outputLanguage] ?? languageVoiceIds["en-US"]!
                let voiceId = selectedGender == "male" ? voiceData.male : voiceData.female
                
                // Generate speech using ElevenLabs
                let audioData = try await ElevenLabsService.shared.synthesizeSpeech(
                    text: text,
                    voiceId: voiceId
                )
                
                // Save the audio file
                let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                let fileURL = getDocumentsDirectory().appendingPathComponent("translatedSpeech_\(timestamp).m4a")
                try audioData.write(to: fileURL)
                self.elevenLabsAudioFileURL = fileURL
                
                // Play the audio automatically
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let audioPlayer = try AVAudioPlayer(data: audioData)
                self.audioPlayer = audioPlayer
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                
                // Update button state
                DispatchQueue.main.async {
                    self.playTranslationButton.setTitle("Playing...", for: .normal)
                    self.playTranslationButton.isEnabled = true
                }
                
            } catch {
                print("❌ Speech synthesis error:", error)
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", 
                                 message: "Failed to synthesize speech. Please check your API key and try again.")
                    self.playTranslationButton.setTitle("Play Translation", for: .normal)
                    self.playTranslationButton.isEnabled = true
                }
            }
        }
    }
    
    @objc func handlePlayTranslation() {
        // Disable button while processing
        playTranslationButton.isEnabled = false
        
        Task {
            do {
                if finalTranslatedText.isEmpty {
                    showAlert(title: "Error", message: "No translation available")
                    playTranslationButton.isEnabled = true
                    return
                }
                
                // Show loading state
                DispatchQueue.main.async {
                    self.playTranslationButton.setTitle("Generating...", for: .normal)
                }
                
                // Get the appropriate voice ID for the output language and gender
                let voiceData = languageVoiceIds[outputLanguage] ?? languageVoiceIds["en-US"]!
                let voiceId = selectedGender == "male" ? voiceData.male : voiceData.female
                
                // Pass the voice ID to the speech synthesis method
                let audioData = try await ElevenLabsService.shared.synthesizeSpeech(
                    text: finalTranslatedText,
                    voiceId: voiceId
                )
                
                // Play the audio
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let audioPlayer = try AVAudioPlayer(data: audioData)
                self.audioPlayer = audioPlayer
                audioPlayer.delegate = self
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                
                // Update button state
                DispatchQueue.main.async {
                    self.playTranslationButton.setTitle("Playing...", for: .normal)
                }
                
            } catch {
                print("❌ Speech synthesis error:", error)
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", 
                                 message: "Failed to synthesize speech. Please check your API key and try again.")
                    self.playTranslationButton.setTitle("Play Translation", for: .normal)
                    self.playTranslationButton.isEnabled = true
                }
            }
        }
    }
    
    private func setupSaveButton() {
        saveRecordingButton = UIButton(type: .system)
        saveRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveRecordingButton)
        
        // Apply modern style
        saveRecordingButton.applyModernStyle()
        saveRecordingButton.setImage(UIImage(systemName: "square.and.arrow.down.fill"), for: .normal)
        saveRecordingButton.setTitle("Save Recording", for: .normal)
        saveRecordingButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        
        // Add target for the save action
        saveRecordingButton.addTarget(self, action: #selector(handleSaveRecording), for: .touchUpInside)
        
        // Setup constraints with more padding
        NSLayoutConstraint.activate([
            saveRecordingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            saveRecordingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            saveRecordingButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 16),
            saveRecordingButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func handleSaveRecording() {
        let alert = UIAlertController(
            title: "Save Recording",
            message: "Enter a name for your recording",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Recording name"
            textField.text = "Recording \(self.recordingCount)"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self?.showError(message: "Please enter a valid name")
                return
            }
            
            self.saveRecording(name: name)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func saveRecording(name: String) {
        guard let audioFileURL = elevenLabsAudioFileURL else {
            showError(message: "No audio file available")
            return
        }
        
        // If name is empty, use UUID as backup
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
            UUID().uuidString : name
        
        let recording = RecordingSession(
            id: UUID(),
            name: finalName,
            dateCreated: Date(),
            duration: currentRecordingDuration,
            audioFileName: audioFileURL.lastPathComponent,
            sourceLanguage: inputLanguage,
            targetLanguage: outputLanguage,
            transcription: finalTranscriptionText,
            translation: finalTranslatedText
        )
        
        do {
            try DatabaseManager.shared.saveRecording(recording)
            recordingCount += 1
            
            // Show success message
            let successAlert = UIAlertController(
                title: "Success",
                message: "Recording saved successfully",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(successAlert, animated: true)
            
            // Reset UI
            saveRecordingButton.isHidden = true
            transcriptionTextView.text = ""
            translationTextView.text = ""
            
        } catch {
            showError(message: "Failed to save recording: \(error.localizedDescription)")
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleLanguageSelection(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let inputLang = userInfo["inputLanguage"] as? String,
           let outputLang = userInfo["outputLanguage"] as? String,
           let gender = userInfo["selectedGender"] as? String,
           let isDetectionEnabled = userInfo["isLanguageDetectionEnabled"] as? Bool {
            
            self.inputLanguage = inputLang
            self.outputLanguage = outputLang
            self.selectedGender = gender
            self.isLanguageDetectionEnabled = isDetectionEnabled
            
            print("✅ Using Input Language: \(inputLang), Output Language: \(outputLang), Detection Enabled: \(isDetectionEnabled)")
            updateLanguageIndicator()
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.playTranslationButton.setTitle("Play Translation", for: .normal)
            self.playTranslationButton.isEnabled = true
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.showAlert(title: "Error", message: "Failed to play audio: \(error?.localizedDescription ?? "Unknown error")")
            self.playTranslationButton.setTitle("Play Translation", for: .normal)
            self.playTranslationButton.isEnabled = true
        }
    }
    
    func setupPlayButton() {
        playTranslationButton = UIButton()
        playTranslationButton.applyModernStyle()
        playTranslationButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playTranslationButton.setTitle("Play Translation", for: .normal)
        playTranslationButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        playTranslationButton.isHidden = true
        
        view.addSubview(playTranslationButton)
        playTranslationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playTranslationButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            playTranslationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            playTranslationButton.topAnchor.constraint(equalTo: saveRecordingButton.bottomAnchor, constant: 8),
            playTranslationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        playTranslationButton.addTarget(self, action: #selector(handlePlayTranslation), for: .touchUpInside)
    }
    
    // Add showAlert method
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private let languageDetectionViewModel = LanguageDetectionViewModel()
    private var detectionStatusLabel: UILabel!
    
    func setupDetectionStatusLabel() {
        detectionStatusLabel = UILabel()
        detectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        detectionStatusLabel.textColor = .white
        detectionStatusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        detectionStatusLabel.textAlignment = .center
        detectionStatusLabel.backgroundColor = UIColor(hex: "#40607e").withAlphaComponent(0.7)
        detectionStatusLabel.layer.cornerRadius = 12
        detectionStatusLabel.clipsToBounds = true
        detectionStatusLabel.isHidden = true
        // Add padding to the label
        detectionStatusLabel.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        view.addSubview(detectionStatusLabel)
        
        NSLayoutConstraint.activate([
            detectionStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            detectionStatusLabel.topAnchor.constraint(equalTo: saveRecordingButton.bottomAnchor, constant: 16),
            detectionStatusLabel.heightAnchor.constraint(equalToConstant: 32),
            // Add minimum width to prevent the label from being too narrow
            detectionStatusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])
        
        // Add a subtle shadow
        detectionStatusLabel.layer.shadowColor = UIColor.black.cgColor
        detectionStatusLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        detectionStatusLabel.layer.shadowRadius = 4
        detectionStatusLabel.layer.shadowOpacity = 0.2
        detectionStatusLabel.layer.masksToBounds = false
    }
    
    // Update the detection status text setting to include an icon
    private func updateDetectionStatus(with language: String) {
        // Only show detection status if language detection is enabled
        guard isLanguageDetectionEnabled else {
            detectionStatusLabel.isHidden = true
            return
        }
        
        // Capitalize the first letter of the language name
        let capitalizedLanguage = language.prefix(1).uppercased() + language.dropFirst().lowercased()
        detectionStatusLabel.text = "🎯 Detected: \(capitalizedLanguage)"
        
        // Animate the label appearance
        detectionStatusLabel.alpha = 0
        detectionStatusLabel.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.detectionStatusLabel.alpha = 1
        }
    }
    
    private func showLanguageMismatchAlert(detectedLanguage: String) {
        // Don't show alert if language detection is disabled
        guard isLanguageDetectionEnabled else { return }
        
        // Don't show the switch option if the detected language is the same as the output language
        let baseOutputLanguage = outputLanguage.split(separator: "-").first?.description ?? outputLanguage
        if let code = languageDetectionViewModel.detectedLanguage?.code,
           (code.split(separator: "-").first?.description ?? code) == baseOutputLanguage {
            
            let alert = UIAlertController(
                title: "Invalid Language Selection",
                message: "You cannot use the same language for input and output. Please choose a different language or continue with your current selection.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Capitalize the first letter of the language name
        let capitalizedLanguage = detectedLanguage.prefix(1).uppercased() + detectedLanguage.dropFirst().lowercased()
        
        let alert = UIAlertController(
            title: "Different Language Detected",
            message: "It seems you're speaking in \(capitalizedLanguage). Would you like to switch to this language?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Switch", style: .default) { [weak self] _ in
            guard let self = self else { return }
            // Stop current recording
            self.handleStopRecording()
            // Update input language
            if let code = self.languageDetectionViewModel.detectedLanguage?.code {
                // Remove any region codes (e.g., "en-US" becomes "en")
                let baseCode = code.split(separator: "-").first?.description ?? code
                self.inputLanguage = baseCode
                UserDefaults.standard.set(baseCode, forKey: "selectedInputLanguage")
                // Update UI to reflect the change
                self.updateLanguageIndicator()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func handleLanguageDetectionToggle(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let isEnabled = userInfo["isEnabled"] as? Bool {
            self.isLanguageDetectionEnabled = isEnabled
            
            // If detection is disabled, hide the detection status label
            if !isEnabled {
                detectionStatusLabel.isHidden = true
            }
        }
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

// Add this extension at the bottom of the file
extension UIButton {
    func applyModernStyle() {
        backgroundColor = .white
        setTitleColor(UIColor(hex: "#40607e"), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Add subtle shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        
        // Add subtle animation on press
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0.9
        }
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.alpha = 1
        }
    }
}
