import SwiftUI
import AVFoundation

struct VoiceCloneWizardView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = VoiceCloneWizardViewModel()
    @State private var voiceIdInput: String = ""
    @State private var showNamePrompt = false
    @State private var voiceName: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var apiKey = ""
    @State private var showingApiKeySection = false
    @State private var showingApiKeyAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Section
                Text("Clone Your Voice")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Description
                Text("Use your own voice for translations by either entering an existing Voice ID or creating a new voice clone.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // API Key Section
                Section(header: Text("API Key")) {
                    if let currentApiKey = APIKeyManager.shared.getElevenLabsApiKey() {
                        HStack {
                            Text("API Key: ").foregroundColor(.gray)
                            Text("•••••" + String(currentApiKey.suffix(4)))
                            Spacer()
                            Button("Change") {
                                apiKey = currentApiKey
                                showingApiKeySection = true
                            }
                        }
                    } else {
                        Button("Set API Key") {
                            showingApiKeySection = true
                        }
                    }
                }
                
                if showingApiKeySection {
                    Section {
                        SecureField("Enter ElevenLabs API Key", text: $apiKey)
                        Button("Save API Key") {
                            APIKeyManager.shared.setElevenLabsApiKey(apiKey)
                            showingApiKeySection = false
                            showingApiKeyAlert = true
                        }
                        .disabled(apiKey.isEmpty)
                    }
                }
                
                // Option 1: Enter Voice ID
                VStack(alignment: .leading, spacing: 12) {
                    Text("Option 1: Enter Existing Voice ID")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter Voice ID", text: $voiceIdInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        // Status indicator
                        if viewModel.verificationStatus != .none {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                                .transition(.scale)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            Task {
                                await viewModel.previewVoice(voiceIdInput)
                            }
                        }) {
                            HStack {
                                Image(systemName: viewModel.isPreviewPlaying ? "stop.fill" : "play.fill")
                                Text(viewModel.isPreviewPlaying ? "Stop" : "Preview")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(voiceIdInput.isEmpty || viewModel.isSaving)
                        
                        Button(action: {
                            Task {
                                if await viewModel.verifyVoiceId(voiceIdInput) {
                                    showNamePrompt = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Save")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(voiceIdInput.isEmpty || viewModel.isSaving || viewModel.isPreviewPlaying)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Option 2: Create New Voice Clone
                VStack(alignment: .leading, spacing: 12) {
                    Text("Option 2: Create New Voice Clone")
                        .font(.headline)
                    
                    Text("Create a new voice clone on ElevenLabs. You'll need to record a 2-minute voice sample.")
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            viewModel.openElevenLabsCloning()
                        }) {
                            HStack {
                                Image(systemName: "link")
                                Text("Open Voice Lab")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isSaving)
                        
                        if !showingApiKeySection {
                            Button(action: {
                                viewModel.openApiKeyInstructions()
                            }) {
                                HStack {
                                    Image(systemName: "key.fill")
                                    Text("How to find your API key")
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(viewModel.isSaving)
            )
            .navigationTitle("Voice Clone Setup")
        }
        .alert("Name Your Voice", isPresented: $showNamePrompt) {
            TextField("Voice Name", text: $voiceName)
            Button("Cancel", role: .cancel) {
                voiceName = ""
            }
            Button("Save") {
                Task {
                    await viewModel.saveVoiceWithName(voiceIdInput, name: voiceName)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("Give your voice a name to help you identify it later.")
        }
        .alert("Voice ID Status", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("API Key Saved", isPresented: $showingApiKeyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your ElevenLabs API key has been saved successfully.")
        }
    }
    
    private var statusIcon: String {
        switch viewModel.verificationStatus {
        case .verifying:
            return "arrow.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        case .none:
            return ""
        }
    }
    
    private var statusColor: Color {
        switch viewModel.verificationStatus {
        case .verifying:
            return .blue
        case .success:
            return .green
        case .failure:
            return .red
        case .none:
            return .clear
        }
    }
}

class VoiceCloneWizardViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isSaving: Bool = false
    @Published var isPreviewPlaying: Bool = false
    @Published var verificationStatus: VerificationStatus = .none
    
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
    }
    
    enum VerificationStatus {
        case none
        case verifying
        case success
        case failure
    }
    
    func openElevenLabsCloning() {
        if let url = URL(string: "https://elevenlabs.io/voice-lab") {
            UIApplication.shared.open(url)
        }
    }
    
    func verifyVoiceId(_ voiceId: String) async -> Bool {
        guard !voiceId.isEmpty else {
            showAlert(message: "Please enter a Voice ID")
            return false
        }
        
        DispatchQueue.main.async {
            self.isSaving = true
            self.verificationStatus = .verifying
        }
        
        do {
            let isValid = try await ElevenLabsService.shared.verifyVoiceId(voiceId)
            
            DispatchQueue.main.async {
                if isValid {
                    self.verificationStatus = .success
                } else {
                    self.verificationStatus = .failure
                    self.showAlert(message: "Invalid Voice ID. Please check and try again.")
                }
                self.isSaving = false
            }
            return isValid
        } catch {
            DispatchQueue.main.async {
                self.verificationStatus = .failure
                self.showAlert(message: "Error verifying Voice ID: \(error.localizedDescription)")
                self.isSaving = false
            }
            return false
        }
    }
    
    func saveVoiceWithName(_ voiceId: String, name: String) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "Please enter a valid name for your voice")
            return
        }
        
        do {
            let newVoice = CustomVoice(name: name, voiceId: voiceId)
            try CustomVoiceManager.shared.saveCustomVoice(newVoice)
            NotificationCenter.default.post(name: Notification.Name("CustomVoiceUpdated"), object: nil)
            
            DispatchQueue.main.async {
                self.showAlert(message: "Voice saved successfully! You can now select 'Custom' as your voice option.")
            }
        } catch {
            showAlert(message: "Failed to save voice: \(error.localizedDescription)")
        }
    }
    
    func previewVoice(_ voiceId: String) async {
        guard !voiceId.isEmpty else {
            alertMessage = "Please enter a valid Voice ID"
            showAlert = true
            return
        }
        
        DispatchQueue.main.async {
            self.isPreviewPlaying = true
        }
        
        do {
            // First stop any existing playback
            audioPlayer?.stop()
            
            // Deactivate current session before changing configuration
            try AVAudioSession.sharedInstance().setActive(false)
            
            // Configure audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            // Use a sample text for preview
            let sampleText = "Hello! This is a preview of your selected voice."
            let audioData = try await ElevenLabsService.shared.synthesizeSpeech(text: sampleText, voiceId: voiceId)
            
            // Create and configure audio player
            let player = try AVAudioPlayer(data: audioData)
            self.audioPlayer = player
            player.delegate = self
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            
        } catch {
            DispatchQueue.main.async {
                self.showAlert(message: "Error previewing voice: \(error.localizedDescription)")
                self.isPreviewPlaying = false
                // Clean up audio session
                try? AVAudioSession.sharedInstance().setActive(false)
            }
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    deinit {
        // Clean up audio session when view model is deallocated
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPreviewPlaying = false
            // Deactivate audio session after playback
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPreviewPlaying = false
            if let error = error {
                self.showAlert(message: "Error playing preview: \(error.localizedDescription)")
            }
            // Deactivate audio session on error
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    func openApiKeyInstructions() {
        if let url = URL(string: "https://docs.elevenlabs.io/api-reference/quick-start/authentication") {
            UIApplication.shared.open(url)
        }
    }
}

struct VoiceCloneWizardView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceCloneWizardView()
    }
} 