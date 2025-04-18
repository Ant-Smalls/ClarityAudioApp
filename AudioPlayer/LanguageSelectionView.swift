//
//  LanguageSelectionView.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 3/2/25.

import SwiftUI

// Custom animated button style using the secondary color.
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#40607e"))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LanguageSelectionView: View {
    @State private var inputLanguage: String = ""
    @State private var outputLanguage: String = ""
    @State private var selectedGender: String = UserDefaults.standard.string(forKey: "selectedVoiceGender") ?? "male"
    @State private var supportedLanguages: [(code: String, name: String, isAvailable: Bool)] = []
    @State private var showingLanguageList: Bool = false
    @State private var detectedLanguage: (code: String, name: String)? = nil
    @State private var showDownloadAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLanguageDetectionEnabled: Bool = UserDefaults.standard.bool(forKey: "isLanguageDetectionEnabled")
    @State private var showVoiceCloneWizard = false
    @State private var hasCustomVoice: Bool = UserDefaults.standard.string(forKey: "customVoiceId") != nil
    @State private var showingCustomVoiceManagement = false
    @StateObject private var customVoiceViewModel = CustomVoiceViewModel()
    
    private let languageService = LanguageDetectionService.shared
    
    // Dictionary mapping language codes to their display names
    let availableLanguages: [String: String] = [
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
    
    private func validateLanguageSelection(newInputLang: String? = nil, newOutputLang: String? = nil) -> Bool {
        let inputToCheck = newInputLang ?? inputLanguage
        let outputToCheck = newOutputLang ?? outputLanguage
        
        // If either language is empty, selection is valid (not complete, but valid)
        if inputToCheck.isEmpty || outputToCheck.isEmpty {
            return true
        }
        
        // Check if languages are the same
        let baseInputLang = inputToCheck.split(separator: "-").first?.description ?? inputToCheck
        let baseOutputLang = outputToCheck.split(separator: "-").first?.description ?? outputToCheck
        
        if baseInputLang == baseOutputLang {
            errorMessage = "Input and output languages cannot be the same"
            showError = true
            return false
        }
        
        return true
    }

    var voiceSelectionSection: some View {
        Section(header: Text("Voice Selection")) {
            Picker("Voice", selection: $selectedGender) {
                Text("Male").tag("male")
                Text("Female").tag("female")
                if !customVoiceViewModel.customVoices.isEmpty {
                    Text("Custom").tag("custom")
                }
            }
            .pickerStyle(.segmented)
            
            if selectedGender == "custom" {
                Menu {
                    ForEach(customVoiceViewModel.customVoices) { voice in
                        Button(action: {
                            customVoiceViewModel.setActiveVoice(voice)
                        }) {
                            HStack {
                                Text(voice.name)
                                if voice.id == customVoiceViewModel.activeVoice?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        showingCustomVoiceManagement = true
                    }) {
                        Label("Manage Voices", systemImage: "gear")
                    }
                } label: {
                    HStack {
                        Text(customVoiceViewModel.activeVoice?.name ?? "Select Custom Voice")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#40607e"))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showingCustomVoiceManagement) {
            CustomVoiceManagementView()
        }
    }

    var body: some View {
        ZStack {
            // Background gradient remains the same
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#23252c"), Color(hex: "#40607e"), Color(hex: "#584d78")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    // Logo with no bottom padding
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    
                    // Title text directly after logo
                    Text("Select Languages")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    // Language Detection Toggle with updated color
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.white)
                        Text("Auto Language Detection")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Toggle("", isOn: $isLanguageDetectionEnabled)
                            .onChange(of: isLanguageDetectionEnabled) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "isLanguageDetectionEnabled")
                                NotificationCenter.default.post(
                                    name: Notification.Name("LanguageDetectionToggled"),
                                    object: nil,
                                    userInfo: ["isEnabled": newValue]
                                )
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#FFFF80"))) // Brighter blue color
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Input Language Menu
                    Menu {
                        ForEach(Array(availableLanguages.keys.sorted()), id: \.self) { code in
                            Button(action: {
                                if validateLanguageSelection(newInputLang: code) {
                                    inputLanguage = code
                                }
                            }) {
                                HStack {
                                    Text(availableLanguages[code] ?? code)
                                    if inputLanguage == code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(inputLanguage.isEmpty ? (isLanguageDetectionEnabled ? "Language Detection Active" : "Select Input Language") : "Input: \(availableLanguages[inputLanguage] ?? inputLanguage)")
                                .foregroundColor(isLanguageDetectionEnabled ? Color.white.opacity(0.5) : .white)
                            Spacer()
                            if isLanguageDetectionEnabled {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(Color.white.opacity(0.5))
                            } else {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#40607e").opacity(isLanguageDetectionEnabled ? 0.3 : 1.0))
                        .cornerRadius(8)
                    }
                    .disabled(isLanguageDetectionEnabled)
                    .onChange(of: isLanguageDetectionEnabled) { newValue in
                        if newValue {
                            // Clear input language when detection is enabled
                            inputLanguage = ""
                        }
                    }
                    
                    // Output Language Menu
                    Menu {
                        ForEach(Array(availableLanguages.keys.sorted()), id: \.self) { code in
                            Button(action: {
                                if validateLanguageSelection(newOutputLang: code) {
                                    outputLanguage = code
                                }
                            }) {
                                HStack {
                                    Text(availableLanguages[code] ?? code)
                                    if outputLanguage == code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(outputLanguage.isEmpty ? "Select Output Language" : "Output: \(availableLanguages[outputLanguage] ?? outputLanguage)")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#40607e"))
                        .cornerRadius(8)
                    }
                    
                    voiceSelectionSection
                    
                    // Clone Voice Button
                    Button(action: {
                        showVoiceCloneWizard = true
                    }) {
                        HStack {
                            Image(systemName: "waveform")
                            Text("Clone Your Voice")
                        }
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .padding(.top, 8)
                    
                    // Language List Button
                    Button(action: { showingLanguageList = true }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("View Supported Languages")
                        }
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .sheet(isPresented: $showingLanguageList) {
                        SupportedLanguagesView(languages: supportedLanguages)
                    }
                    
                    // Detected Language Info (if available)
                    if let detected = detectedLanguage {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Detected: \(detected.name)")
                            if !languageService.isLanguageAvailable(detected.code) {
                                Button(action: {
                                    alertMessage = "Please download \(detected.name) in Settings > General > Language & Region"
                                    showDownloadAlert = true
                                }) {
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Continue Button
                    Button(action: {
                        if (!inputLanguage.isEmpty || isLanguageDetectionEnabled) && !outputLanguage.isEmpty {
                            var userInfo: [String: Any] = [
                                "inputLanguage": inputLanguage,
                                "outputLanguage": outputLanguage,
                                "selectedGender": selectedGender,
                                "isLanguageDetectionEnabled": isLanguageDetectionEnabled
                            ]
                            
                            // Add custom voice ID if custom voice is selected
                            if selectedGender == "custom", let activeVoice = customVoiceViewModel.activeVoice {
                                userInfo["customVoiceId"] = activeVoice.voiceId
                                UserDefaults.standard.set(activeVoice.voiceId, forKey: "customVoiceId")
                            } else {
                                UserDefaults.standard.removeObject(forKey: "customVoiceId")
                            }
                            
                            // Update existing notification to include detection status and custom voice
                            NotificationCenter.default.post(
                                name: Notification.Name("LanguagesSelected"),
                                object: nil,
                                userInfo: userInfo
                            )
                            
                            // Save all selections to UserDefaults
                            UserDefaults.standard.set(inputLanguage, forKey: "selectedInputLanguage")
                            UserDefaults.standard.set(outputLanguage, forKey: "selectedOutputLanguage")
                            UserDefaults.standard.set(selectedGender, forKey: "selectedVoiceGender")
                            UserDefaults.standard.set(isLanguageDetectionEnabled, forKey: "isLanguageDetectionEnabled")
                            UserDefaults.standard.synchronize()
                            
                            // Post notification to switch tabs
                            NotificationCenter.default.post(
                                name: Notification.Name("SwitchToRecordTab"),
                                object: nil
                            )
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(AnimatedButtonStyle())
                    .opacity((!inputLanguage.isEmpty || isLanguageDetectionEnabled) && !outputLanguage.isEmpty ? 1.0 : 0.5)
                    .disabled((!inputLanguage.isEmpty || isLanguageDetectionEnabled) && !outputLanguage.isEmpty ? false : true)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .sheet(isPresented: $showVoiceCloneWizard) {
                VoiceCloneWizardView()
            }
            .alert("Invalid Selection", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Add loading of detection status
            isLanguageDetectionEnabled = UserDefaults.standard.bool(forKey: "isLanguageDetectionEnabled")
            
            supportedLanguages = languageService.getSupportedLanguagesStatus()
            
            // Load saved languages from UserDefaults and normalize the codes
            if let savedInput = UserDefaults.standard.string(forKey: "selectedInputLanguage") {
                let baseCode = savedInput.split(separator: "-").first?.description ?? savedInput
                // Only set if it's different from output language
                if baseCode != outputLanguage {
                    inputLanguage = baseCode
                }
            }
            if let savedOutput = UserDefaults.standard.string(forKey: "selectedOutputLanguage") {
                let baseCode = savedOutput.split(separator: "-").first?.description ?? savedOutput
                // Only set if it's different from input language
                if baseCode != inputLanguage {
                    outputLanguage = baseCode
                }
            }
            
            // Check for custom voice on appear
            checkCustomVoiceAvailability()
            
            // Add observer for custom voice updates
            NotificationCenter.default.addObserver(
                forName: Notification.Name("CustomVoiceUpdated"),
                object: nil,
                queue: .main
            ) { _ in
                checkCustomVoiceAvailability()
            }
        }
    }
    
    private func checkCustomVoiceAvailability() {
        hasCustomVoice = UserDefaults.standard.string(forKey: "customVoiceId") != nil
        // If custom voice was removed and it was selected, switch to male
        if !hasCustomVoice && selectedGender == "custom" {
            selectedGender = "male"
            UserDefaults.standard.set("male", forKey: "selectedVoiceGender")
        }
    }
}

// Updated SupportedLanguagesView
struct SupportedLanguagesView: View {
    let languages: [(code: String, name: String, isAvailable: Bool)]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(languages, id: \.code) { language in
                HStack {
                    Text(language.name)
                    Spacer()
                    if language.isAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button(action: {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Supported Languages")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ViewControllerWrapper: UIViewControllerRepresentable {
    var inputLanguage: String
    var outputLanguage: String

    func makeUIViewController(context: Context) -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {
            fatalError("❌ Could not find ViewController in Storyboard.")
        }
        viewController.inputLanguage = inputLanguage
        viewController.outputLanguage = outputLanguage
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView()
    }
}
