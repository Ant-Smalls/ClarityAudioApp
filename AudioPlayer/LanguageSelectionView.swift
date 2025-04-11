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
    
    // Dictionary mapping language codes to their display names
    let availableLanguages: [String: String] = [
        "en-US": "English (US)",
        "es": "Spanish",
        "de": "German",
        "pt-BR": "Portuguese (Brazil)",
        "ja": "Japanese",
        "fr": "French",
        "it": "Italian",
        "ru": "Russian"
    ]

    var body: some View {
        ZStack {
            // Background gradient remains the same
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#23252c"), Color(hex: "#40607e"), Color(hex: "#584d78")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App logo image, now larger.
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.bottom, 20)
                
                // Title text.
                Text("Select Languages")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Input Language Menu
                Menu {
                    ForEach(Array(availableLanguages.keys.sorted()), id: \.self) { code in
                        Button(action: { inputLanguage = code }) {
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
                        Text(inputLanguage.isEmpty ? "Select Input Language" : "Input: \(availableLanguages[inputLanguage] ?? inputLanguage)")
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
                
                // Output Language Menu
                Menu {
                    ForEach(Array(availableLanguages.keys.sorted()), id: \.self) { code in
                        Button(action: { outputLanguage = code }) {
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
                
                // Continue Button
                Button(action: {
                    if !inputLanguage.isEmpty && !outputLanguage.isEmpty {
                        // Post notification with selected languages
                        NotificationCenter.default.post(
                            name: Notification.Name("LanguagesSelected"),
                            object: nil,
                            userInfo: [
                                "inputLanguage": inputLanguage,
                                "outputLanguage": outputLanguage
                            ]
                        )
                        
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
                .opacity(inputLanguage.isEmpty || outputLanguage.isEmpty ? 0.5 : 1.0)
                .disabled(inputLanguage.isEmpty || outputLanguage.isEmpty)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 60)
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
