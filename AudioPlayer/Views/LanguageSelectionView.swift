import SwiftUI

struct LanguageSelectionView: View {
    @State private var inputLanguage: String = "en-US"
    @State private var outputLanguage: String = "ja"
    
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
                // Logo and App Name
                VStack(spacing: 10) {
                    Image(systemName: "waveform.and.mic")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                    
                    Text("clarity")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                // Title
                Text("Select Input & Output Languages")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
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
                
                // Continue Button
                Button(action: {
                    navigateToMainView()
                }) {
                    Text("Continue")
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
    }
    
    private func navigateToMainView() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate else {
            return
        }
        
        // Create RecordView with selected languages
        let recordView = RecordView(inputLanguage: inputLanguage, outputLanguage: outputLanguage)
        let recordHostingController = UIHostingController(rootView: recordView)
        recordHostingController.modalPresentationStyle = .fullScreen
        
        let navigationController = UINavigationController(rootViewController: recordHostingController)
        navigationController.setNavigationBarHidden(true, animated: false)
        sceneDelegate.window?.rootViewController = navigationController
        sceneDelegate.window?.makeKeyAndVisible()
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView()
    }
} 