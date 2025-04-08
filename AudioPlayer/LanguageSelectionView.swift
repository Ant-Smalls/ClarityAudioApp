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
    @State private var inputLanguage: String = "en-US"
    @State private var outputLanguage: String = "es"
    let languages = ["en-US", "es", "de", "pt-BR", "ja"]

    var body: some View {
        ZStack {
            // A smooth gradient background using the defined primary, secondary, and tertiary colors.
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
                Text("Select Input & Output Languages")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Input Language Picker.
                Picker("Select Input Language", selection: $inputLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(hex: "#40607e"))
                .cornerRadius(8)
                
                // Output Language Picker.
                Picker("Select Output Language", selection: $outputLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(hex: "#40607e"))
                .cornerRadius(8)
                
                // Continue Button.
                Button(action: {
                    navigateToMainView()
                }) {
                    Text("Continue")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .buttonStyle(AnimatedButtonStyle())
            }
            // Move the entire VStack toward the top while keeping it horizontally centered.
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 60) // Adjust this value for desired vertical placement.
        }
    }

    func navigateToMainView() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive })?.delegate as? SceneDelegate,
              let navigationController = sceneDelegate.window?.rootViewController as? UINavigationController else {
            print("❌ NavigationController not found")
            return
        }
        let mainViewController = UIHostingController(rootView: ViewControllerWrapper(inputLanguage: inputLanguage, outputLanguage: outputLanguage))
        DispatchQueue.main.async {
            navigationController.pushViewController(mainViewController, animated: true)
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
