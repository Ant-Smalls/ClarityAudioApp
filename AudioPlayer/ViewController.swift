//
//  ViewController.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 12/6/24.
//


import UIKit
import AVFoundation
import Speech
import Translation
import SwiftUI

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate {
    
    // Properties
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var isRecording = false
    var audioFileName: URL?
    var recordingCount = 1
    var recordedFiles: [URL] = []
    
    // Dynamic Language Selection
    var inputLanguage: String = "en-US" // Default, will be set dynamically
    var outputLanguage: String = "es" // Default, will be set dynamically
    var finalTranscriptionText: String = ""  // ✅ Stores the full transcription
    var finalTranslatedText: String = ""     // ✅ Stores only the translation

    var speechRecognizer: SFSpeechRecognizer?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var speechSynthesizer = AVSpeechSynthesizer()
    var speechSynthesizerDelegate: SpeechSynthesizerDelegate?
    var translationAudioQueue: [URL] = []
    
    var elevenLabsAudioFileURL: URL?
    
    // UI Elements
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var translationTextView: UITextView!
    @IBOutlet weak var playTranslatedAudioButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupAudioSession()
        requestSpeechPermission()
        
        // Update UI for selected languages
        stopRecordButton.isHidden = true
        print("✅ Using Input Language: \(inputLanguage), Output Language: \(outputLanguage)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ ViewController appeared successfully!") // Debugging statement
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("⚠️ ViewController is disappearing, cleaning up translation tasks.")

        // ✅ Remove any existing SwiftUI hosting controller
        for child in children {
            if let hostingController = child as? UIHostingController<TranslationView> {
                hostingController.willMove(toParent: nil)
                hostingController.view.removeFromSuperview()
                hostingController.removeFromParent()
            }
        }

        // ✅ Stop any ongoing translations
        self.finalTranslatedText = ""
    }


    
    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized.")
                    self.recordButton?.isEnabled = true // ✅ Use optional chaining
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
    
    @IBAction func handleRecord() {
        if !audioEngine.isRunning {
            startRealTimeTranscription()

            // ✅ Hide "Record Audio" button and show "Stop Recording"
            recordButton.isHidden = true
            stopRecordButton.isHidden = false
        }
    }
    
    
    @IBAction func handleStopRecording() {
        print("🛑 Stopping Recording...")

        // ✅ Step 1: Immediately detach the Speech Recognition Service so it doesn't throw errors
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
        self.recognitionRequest = nil

        // ✅ Step 2: Stop audio processing to prevent further recognition
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.audioEngine.stop()

        // ✅ Step 3: Ignore any further recognition errors (prevents kAFAssistantErrorDomain 1101)
        self.speechRecognizer = nil  // ✅ Completely detach speech recognizer

        let finalText = self.transcriptionTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // ✅ Step 4: Ignore empty final transcriptions
        if finalText.isEmpty {
            print("⚠️ Ignoring empty final transcription. Nothing to translate.")
            return
        }

        print("🌍 Finalizing translation for: \(finalText)")

        // ✅ Step 5: Store final transcription and translate
        self.finalTranscriptionText = finalText
        self.presentTranslationView(with: finalText)

        // ✅ Step 6: Ensure audio is generated only if translation exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.finalTranslatedText.isEmpty {
                self.generateAudioFromTranslation(self.finalTranslatedText)
            } else {
                print("⚠️ No translated text available for audio generation.")
            }
        }

        // ✅ Step 7: Restore UI state
        self.recordButton.isHidden = false
        self.stopRecordButton.isHidden = true
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
                print("📝 Transcribed: \(transcribedText)") // ✅ Debugging
                
                if self.recognitionTask == nil {
                                print("⚠️ Skipping translation: Recognition was canceled.")
                                return
                            }

                
                DispatchQueue.main.async {
                    self.transcriptionTextView.text = transcribedText
                    self.presentTranslationView(with: transcribedText) // ✅ Automatically translate each update
                }
            }
            
            if let error = error as NSError?{
                if error.code == 1110 {
                            print("⚠️ Ignoring 'No speech detected' error (User stopped speaking).")
                            return
                }
                else if error.code == 301 {
                    print("⚠️ Ignoring 'Recognition request was canceled' error (User stopped recording).")
                    return
                }

                print("❌ Transcription error: \(error.localizedDescription) \(error.code)")
            }
        }
    }

    
    func presentTranslationView(with text: String) {
        // ✅ Prevent translation if the ViewController is disappearing
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

                // ✅ Store texts separately
                self.finalTranscriptionText = text
                self.finalTranslatedText = translatedText

                // ✅ Update separate UI elements
                self.transcriptionTextView.text = text
                self.translationTextView.text = translatedText
            }
        }

        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0) // Hide SwiftUI view
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
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

        // ✅ Enable the play button after generating audio
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

class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private let completion: () -> Void
    init(completion: @escaping () -> Void) { self.completion = completion }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion()
    }
}
