import SwiftUI

struct LanguageSelectionView: View {
    @State private var inputLanguage: String
    @State private var outputLanguage: String
    @State private var showingAlert = false
    
    init(initialInputLanguage: String = "en-US", initialOutputLanguage: String = "ja") {
        _inputLanguage = State(initialValue: initialInputLanguage)
        _outputLanguage = State(initialValue: initialOutputLanguage)
    }
    
    private let languages = [
        "en-US": "English (US)",
        "es-ES": "Spanish",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian",
        "ja": "Japanese",
        "ko": "Korean",
        "zh": "Chinese"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    AppTheme.secondaryColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    // App logo image, now larger.
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(.bottom, 20)
                    
                    // Title text.
                    Text("Select Input & Output Languages")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Language Selection
                VStack(spacing: 25) {
                    // Input Language Picker
                    Menu {
                        ForEach(Array(languages.keys.sorted()), id: \.self) { code in
                            Button(action: {
                                inputLanguage = code
                            }) {
                                Text(languages[code] ?? code)
                            }
                        }
                    } label: {
                        HStack {
                            Text(languages[inputLanguage] ?? inputLanguage)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Output Language Picker
                    Menu {
                        ForEach(Array(languages.keys.sorted()), id: \.self) { code in
                            Button(action: {
                                outputLanguage = code
                            }) {
                                Text(languages[code] ?? code)
                            }
                        }
                    } label: {
                        HStack {
                            Text(languages[outputLanguage] ?? outputLanguage)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Apply Button
                Button(action: {
                    applyLanguageSettings()
                }) {
                    Text("Apply Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Languages Updated"),
                message: Text("Your language settings have been updated."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func applyLanguageSettings() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate else {
            return
        }
        
        // Create new tab controller with updated languages
        let tabController = MainTabBarController(
            inputLanguage: inputLanguage,
            outputLanguage: outputLanguage
        )
        
        sceneDelegate.window?.rootViewController = tabController
        sceneDelegate.window?.makeKeyAndVisible()
        
        showingAlert = true
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView()
    }
} 