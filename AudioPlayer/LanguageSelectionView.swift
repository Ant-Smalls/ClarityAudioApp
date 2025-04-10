// LanguageSelectionView.swift
// AudioPlayer
// Created by Yusuke Abe, Tadija Ciric, Anthony Smaldore on 3/2/25.
///
// SwiftUI view allowing users to select the input/output language before navigating
// to the main translation and transcription interface.


import SwiftUI
import Translation


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



// SwiftUI view where users choose the source and target translation languages.
// On valid selection, it checks translation availability before proceeding.
struct LanguageSelectionView: View {
    @State private var inputLanguage: String = "en-US"
    @State private var outputLanguage: String = "es"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var shouldPrepareTranslation = false
    
    let languages = ["en-US", "es", "de", "pt-BR", "ja", "fr", "el"]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#23252c"), Color(hex: "#40607e"), Color(hex: "#584d78")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.bottom, 20)
                
                // Title
                Text("Select Input & Output Languages")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Input Language Picker
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
                
                // Output Language Picker
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
                
                // Continue Button
                Button(action: {
                    checkLanguageAvailability()
                }) {
                    Text("Continue")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .buttonStyle(AnimatedButtonStyle())
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Translation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 60)
        }
        
        
        if shouldPrepareTranslation {
            TranslationPreparationView(
                inputLanguage: Locale.Language(identifier: inputLanguage),
                outputLanguage: Locale.Language(identifier: outputLanguage),
                onReady: {
                    shouldPrepareTranslation = false
                    navigateToMainView()
                },
                onError: { message in
                    shouldPrepareTranslation = false
                    alertMessage = message
                    showAlert = true
                }
            )
        }
    }
    
    
    
    // Navigates to the ViewController with the selected language settings.
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
    
    
    
    // Verifies that the selected languages are supported for translation.
    func checkLanguageAvailability() {
        Task {
            
            let availability = LanguageAvailability()
            let source = Locale.Language(identifier: inputLanguage)
            let target = Locale.Language(identifier: outputLanguage)

            let status = await availability.status(from: source, to: target)
            switch status {
            case .installed:
                navigateToMainView()
            case .supported:
                shouldPrepareTranslation = true // triggers TranslationPreparationView
            case .unsupported:
                alertMessage = "Translation from \(inputLanguage) to \(outputLanguage) is not supported."
                showAlert = true
            @unknown default:
                alertMessage = "Unexpected translation status."
                showAlert = true
            }
        }
    }

    
    
    
    // Wraps the UIKit ViewController for use in SwiftUI.
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
    
    
    
    // Preview for SwiftUI canvas.
    struct LanguageSelectionView_Previews: PreviewProvider {
        static var previews: some View {
            LanguageSelectionView()
        }
    }
}



    // View responsible for preparing system translation support (e.g. downloads if required).
    struct TranslationPreparationView: View {
        let inputLanguage: Locale.Language
        let outputLanguage: Locale.Language
        let onReady: () -> Void
        let onError: (String) -> Void

        var body: some View {
            Color.clear
                .translationTask(source: inputLanguage, target: outputLanguage) { session in
                    Task {
                        do {
                            try await session.prepareTranslation()
                            DispatchQueue.main.async {
                                onReady()
                            }
                        } catch {
                            DispatchQueue.main.async {
                                onError("Failed to prepare translation: \(error.localizedDescription)")
                            }
                        }
                    }
                }
        }
}








































/*
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
 
 
 /*
  
  NOT WORKING TESTING FOR PREPARING LANGUAGE DOWNLOAD
  
  
  
  
  //
  //  LanguageSelectionView.swift
  //  AudioPlayer
  //
  //  Created by Anthony Smaldore on 3/2/25.

  import SwiftUI
  import Foundation
  import Translation

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
      @State private var showAlert = false
      @State private var alertMessage = ""
      @State private var isLoading = false

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
                      prepareTranslationResources()
                  }) {
                      if isLoading {
                          ProgressView()
                              .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      } else {
                          Text("Continue")
                              .font(.system(size: 20, weight: .semibold, design: .rounded))
                      }
                  }
                  .disabled(isLoading)
                  .buttonStyle(AnimatedButtonStyle())
                  .alert(isPresented: $showAlert) {
                      Alert(title: Text("Translation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                  }
              }
              .padding(.horizontal, 20)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
              .padding(.top, 60)
          }
      }

      func prepareTranslationResources() {
          isLoading = true
          Task {
              do {
                  let source = Locale.Language(identifier: inputLanguage)
                  let target = Locale.Language(identifier: outputLanguage)
                  let availability = LanguageAvailability()

                  let status = try await availability.status(from: source, to: target)

                  switch status {
                  case .installed:
                      navigateToMainView()
                  case .supported:
                      let session = TranslationSession(sourceLanguage: source, targetLanguage: target)
                      try await session.prepareTranslation()
                      navigateToMainView()
                  case .unsupported:
                      alertMessage = "Translation from \(inputLanguage) to \(outputLanguage) is not supported."
                      showAlert = true
                  @unknown default:
                      alertMessage = "Unexpected translation availability status."
                      showAlert = true
                  }
              } catch {
                  alertMessage = "Failed to prepare translation resources: \(error.localizedDescription)"
                  showAlert = true
              }
              isLoading = false
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

  
  
  */*/
