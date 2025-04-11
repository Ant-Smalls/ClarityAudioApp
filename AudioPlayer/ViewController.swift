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

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate {
    
    // MARK: - Properties
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var isRecording = false
    var audioFileName: URL?
    var recordingCount = 1
    var recordedFiles: [URL] = []
    
    // Dynamic language selections.
    var inputLanguage: String = "en-US"
    var outputLanguage: String = "es"
    var finalTranscriptionText: String = ""
    var finalTranslatedText: String = ""
    
    // Language display names
    private let languageDisplayNames: [String: String] = [
        "en-US": "English",
        "es": "Spanish",
        "de": "German",
        "pt-BR": "Portuguese",
        "ja": "Japanese",
        "fr": "French",
        "it": "Italian",
        "ru": "Russian"
    ]
    
    // Language indicator label
    private var languageIndicatorLabel: UILabel!
    
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
    
    // Add new properties
    private var currentRecordingDuration: TimeInterval = 0
    private var recordingStartTime: Date?
    
    // MARK: - UI Elements (Connected via Storyboard)
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var translationTextView: UITextView!
    @IBOutlet weak var playTranslatedAudioButton: UIButton!
    
    // Remove IBOutlet and make it a regular property
    private var saveRecordingButton: UIButton!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        applyGradientBackground()
        setupAudioSession()
        requestSpeechPermission()
        setupSaveButton()
        styleUI()
        
        // Set initial button states.
        recordButton.alpha = 1
        stopRecordButton.alpha = 0
        saveRecordingButton.isHidden = true
        
        print("✅ Using Input Language: \(inputLanguage), Output Language: \(outputLanguage)")
        
        // Add observer for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLanguageSelection),
            name: Notification.Name("LanguagesSelected"),
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
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            recordButton.widthAnchor.constraint(equalToConstant: 80), // Increased from 60 to 80
            recordButton.heightAnchor.constraint(equalToConstant: 80), // Increased from 60 to 80
            
            stopRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopRecordButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            stopRecordButton.widthAnchor.constraint(equalToConstant: 80), // Increased from 60 to 80
            stopRecordButton.heightAnchor.constraint(equalToConstant: 80), // Increased from 60 to 80
        ])
        
        // Style play translated audio button
        playTranslatedAudioButton.applyModernStyle()
        playTranslatedAudioButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playTranslatedAudioButton.setTitle("Play Translation", for: .normal)
        playTranslatedAudioButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        
        // Style text views
        transcriptionTextView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        transcriptionTextView.textColor = .white
        transcriptionTextView.font = .systemFont(ofSize: 16, weight: .regular)
        transcriptionTextView.layer.cornerRadius = 12
        transcriptionTextView.clipsToBounds = true
        
        // Add language indicator label
        languageIndicatorLabel = UILabel()
        languageIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(languageIndicatorLabel)
        
        // Style the label
        languageIndicatorLabel.textColor = .white
        languageIndicatorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        languageIndicatorLabel.textAlignment = .center
        updateLanguageIndicator()
        
        // Add constraints
        NSLayoutConstraint.activate([
            languageIndicatorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            languageIndicatorLabel.topAnchor.constraint(equalTo: transcriptionTextView.bottomAnchor, constant: 8),
            languageIndicatorLabel.bottomAnchor.constraint(equalTo: translationTextView.topAnchor, constant: -8)
        ])
        
        translationTextView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        translationTextView.textColor = .white
        translationTextView.font = .systemFont(ofSize: 16, weight: .regular)
        translationTextView.layer.cornerRadius = 12
        translationTextView.clipsToBounds = true
        
        // Adjust save button position to be below record/stop buttons
        NSLayoutConstraint.activate([
            saveRecordingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            saveRecordingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            saveRecordingButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            saveRecordingButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateLanguageIndicator() {
        let inputName = languageDisplayNames[inputLanguage] ?? inputLanguage
        let outputName = languageDisplayNames[outputLanguage] ?? outputLanguage
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
            startRealTimeTranscription()
            recordingStartTime = Date()
            UIView.animate(withDuration: 0.3) {
                self.recordButton.alpha = 0
                self.stopRecordButton.alpha = 1
                self.saveRecordingButton.isHidden = true
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
        if finalText.isEmpty {
            print("⚠️ Ignoring empty final transcription. Nothing to translate.")
            return
        }
        
        print("🌍 Finalizing translation for: \(finalText)")
        self.finalTranscriptionText = finalText
        self.presentTranslationView(with: finalText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.finalTranslatedText.isEmpty {
                self.generateAudioFromTranslation(self.finalTranslatedText)
            } else {
                print("⚠️ No translated text available for audio generation.")
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.recordButton.alpha = 1
            self.stopRecordButton.alpha = 0
            self.saveRecordingButton.isHidden = false
        }
    }
    
    func startRealTimeTranscription() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: inputLanguage))
        guard let speechRecognizer = speechRecognizer else {
            print("❌ Speech recognizer not available for language: \(inputLanguage)")
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
                    self.transcriptionTextView.text = transcribedText
                    self.presentTranslationView(with: transcribedText)
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
            saveRecordingButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
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
           let outputLang = userInfo["outputLanguage"] as? String {
            self.inputLanguage = inputLang
            self.outputLanguage = outputLang
            updateLanguageIndicator()
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
