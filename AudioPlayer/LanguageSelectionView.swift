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
            .background(AppTheme.secondaryColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LanguageSelectionView: View {
    @State private var inputLanguage: String = "en-US"
    @State private var outputLanguage: String = "es-ES"
    
    private let languages = [
        "en-US": "English (US)",
        "es-ES": "Spanish",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.backgroundColor,
                    AppTheme.secondaryColor,
                    AppTheme.accentColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Select Languages")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                // Input Language Picker
                VStack(alignment: .leading) {
                    Text("Input Language")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Picker("Input Language", selection: $inputLanguage) {
                        ForEach(Array(languages.keys.sorted()), id: \.self) { code in
                            Text(languages[code] ?? code)
                                .foregroundColor(.white)
                                .tag(code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.white)
                    .padding()
                    .background(AppTheme.secondaryColor)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Output Language Picker
                VStack(alignment: .leading) {
                    Text("Output Language")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Picker("Output Language", selection: $outputLanguage) {
                        ForEach(Array(languages.keys.sorted()), id: \.self) { code in
                            Text(languages[code] ?? code)
                                .foregroundColor(.white)
                                .tag(code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(.white)
                    .padding()
                    .background(AppTheme.secondaryColor)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Button(action: {
                    navigateToMainView()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accentColor)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
    
    private func navigateToMainView() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate else {
            return
        }
        
        // Create view controller from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {
            print("❌ Could not instantiate ViewController from storyboard")
            return
        }
        
        // Set the languages
        viewController.inputLanguage = inputLanguage
        viewController.outputLanguage = outputLanguage
        
        let navigationController = UINavigationController(rootViewController: viewController)
        sceneDelegate.window?.rootViewController = navigationController
        sceneDelegate.window?.makeKeyAndVisible()
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
