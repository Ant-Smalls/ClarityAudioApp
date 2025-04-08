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
    
    // MARK: - UI Elements (Connected via Storyboard)
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var translationTextView: UITextView!
    @IBOutlet weak var playTranslatedAudioButton: UIButton!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        applyGradientBackground()
        setupAudioSession()
        requestSpeechPermission()
        styleUI()
        
        // Set initial button states.
        recordButton.alpha = 1
        stopRecordButton.alpha = 0
        
        print("✅ Using Input Language: \(inputLanguage), Output Language: \(outputLanguage)")
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
        // Set a modern, clean font for buttons.
        let buttonFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        recordButton.titleLabel?.font = buttonFont
        stopRecordButton.titleLabel?.font = buttonFont
        playTranslatedAudioButton.titleLabel?.font = buttonFont
        
        // Style record button.
        recordButton.backgroundColor = UIColor(hex: "#40607e")
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 8
        
        // Style stop record button.
        stopRecordButton.backgroundColor = UIColor(hex: "#40607e")
        stopRecordButton.setTitleColor(.white, for: .normal)
        stopRecordButton.layer.cornerRadius = 8
        
        // Style play translated audio button.
        playTranslatedAudioButton.backgroundColor = UIColor(hex: "#40607e")
        playTranslatedAudioButton.setTitleColor(.white, for: .normal)
        playTranslatedAudioButton.layer.cornerRadius = 8
        
        // Style transcription text view.
        transcriptionTextView.backgroundColor = UIColor(hex: "#584d78")
        transcriptionTextView.textColor = .white
        transcriptionTextView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        transcriptionTextView.layer.cornerRadius = 8
        transcriptionTextView.clipsToBounds = true
        
        // Style translation text view.
        translationTextView.backgroundColor = UIColor(hex: "#584d78")
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
    
    // MARK: - Recording Actions
    @IBAction func handleRecord() {
        if !audioEngine.isRunning {
            startRealTimeTranscription()
            UIView.animate(withDuration: 0.3) {
                self.recordButton.alpha = 0
                self.stopRecordButton.alpha = 1
            }
        }
    }
    
    @IBAction func handleStopRecording() {
        print("🛑 Stopping Recording...")
        
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
}

// MARK: - SpeechSynthesizerDelegate
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let completion: () -> Void
    init(completion: @escaping () -> Void) { self.completion = completion }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion()
    }
}
