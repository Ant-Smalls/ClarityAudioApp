//
//  ViewController.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 12/6/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // Properties
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var isRecording = false
    var audioFileName: URL?
    var recordingCount = 1
    var recordedFiles: [URL] = []
    
    let transcriber = AssemblyAITranscriber(apiKey: "")
    let translator = DeepLTranslator(apiKey: "")
    let elevenLabsAPI = ElevenLabsAPI(apiKey: "")
       var elevenLabsAudioFileURL: URL?
    
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var elevenLabsPlayButton: UIButton!


    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupAudioSession()
        
        playButton.isEnabled = false
        playButton.setTitleColor(.blue, for: .normal)
        playButton.setTitleColor(.gray, for: .disabled)
        elevenLabsPlayButton.isEnabled = false
        elevenLabsPlayButton.setTitleColor(.blue, for: .normal)
        elevenLabsPlayButton.setTitleColor(.gray, for: .disabled)
    }
    
    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
                try session.setActive(true)
                print("✅ Audio session configured for Bluetooth playback.")
            }
            catch{
                print("❌ Failed to setup audio session:", error)
            }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getNewAudioFileURL() -> URL {
        // Create a unique file name based on timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        return getDocumentsDirectory().appendingPathComponent("recording_\(timestamp).m4a")
    }
    
    @IBAction func handleRecord() {
        if isRecording {
            // Stop recording
            audioRecorder?.stop()
            isRecording = false
            recordButton.setTitle("Start Recording", for: .normal)
            
            guard let audioFileName = audioFileName else { return }
            recordedFiles.append(audioFileName)
            recordingCount += 1
                
            playButton.setTitle("Play \(audioFileName.lastPathComponent)", for: .normal)
            playButton.isEnabled = true
                
            // Start transcription process
            transcribeAudioFile(audioFileName)
        } else {
            // Start recording
            let audioFileURL = getNewAudioFileURL()
            audioFileName = audioFileURL
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
                audioRecorder?.record()
                isRecording = true
                recordButton.setTitle("Stop Recording", for: .normal)
            } catch {
                print("Failed to start recording:", error)
            }
        }
    }
    
    func transcribeAudioFile(_ fileURL: URL) {
            // Upload audio and start transcription
            transcriber.uploadAudioFile(localFileURL: fileURL) { [weak self] result in
                switch result {
                case .success(let uploadedURL):
                    print("File uploaded successfully: \(uploadedURL)")
                    self?.requestTranscription(for: uploadedURL)
                case .failure(let error):
                    print("Error uploading file: \(error)")
                }
            }
        }
    
    
    func requestTranscription(for uploadedURL: String) {
        transcriber.requestTranscription(audioFileURL: uploadedURL) { [weak self] result in
            switch result {
            case .success(let transcription):
                print("Transcription completed: \(transcription)")
                DispatchQueue.main.async {
                    // Translate the transcription before sending it to Eleven Labs
                    self?.translateAndGenerateAudio(transcription)
                }
            case .failure(let error):
                print("Error during transcription: \(error)")
            }
        }
    }
    
    
    func translateAndGenerateAudio(_ originalText: String) {
        let targetLanguage = "EN-US" // Change to desired language code 

        translator.translateText(originalText, targetLang: targetLanguage) { [weak self] result in
            switch result {
            case .success(let translatedText):
                print("Translation completed: \(translatedText)")
                DispatchQueue.main.async {
                    self?.updateTranscriptionTextView(with: translatedText)
                    self?.generateAudioFromTranscription(translatedText) // Send to Eleven Labs
                }
            case .failure(let error):
                print("Error during translation: \(error)")
            }
        }
    }

        
    func updateTranscriptionTextView(with transcription: String) {
           transcriptionTextView.text = transcription
       }
    
        func showTranscriptionAlert(_ transcription: String) {
            let alert = UIAlertController(title: "Transcription", message: transcription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
    func generateAudioFromTranscription(_ transcription: String) {
            elevenLabsAPI.generateSpeech(from: transcription) { [weak self] result in
                switch result {
                case .success(let audioFileURL):
                    DispatchQueue.main.async {
                        self?.elevenLabsAudioFileURL = audioFileURL
                        self?.elevenLabsPlayButton.isEnabled = true
                    }
                case .failure(let error):
                    print("Error generating audio: \(error)")
                }
            }
        }
    
    @IBAction func handlePlayElevenLabsAudio() {
            guard let elevenLabsAudioFileURL = elevenLabsAudioFileURL else {
                print("No Eleven Labs audio file available to play")
                return
            }
            
            do {
                setupAudioSession() // ✅ Ensure Bluetooth is configured
                audioPlayer = try AVAudioPlayer(contentsOf: elevenLabsAudioFileURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("✅ Playing Eleven Labs audio through JBL (if connected).")
            }
            catch {
                print("❌ Failed to play Eleven Labs audio:", error)
            }
        }
    
    @IBAction func handlePlay() {
        guard let lastRecording = recordedFiles.last else {
            print("No recordings available to play")
            return
        }
        
        do {
            setupAudioSession() // ✅ Ensure Bluetooth output before playing
            audioPlayer = try AVAudioPlayer(contentsOf: lastRecording)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("✅ Playing audio through JBL (if connected).")
        } catch {
            print("❌ Failed to play audio:", error)
        }

    }
}
