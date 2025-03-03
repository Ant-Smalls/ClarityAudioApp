//
//  LanguageSelectionView.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 3/2/25.
//

import SwiftUI


struct LanguageSelectionView: View {
    @State private var inputLanguage: String = "en-US"
    @State private var outputLanguage: String = "es"
    let languages = ["en-US", "es", "de", "pt-BR", "ja"]

    var body: some View {
        VStack {
            Text("Select Input & Output Languages")
                .font(.title)
                .padding()

            Picker("Select Input Language", selection: $inputLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            Picker("Select Output Language", selection: $outputLanguage) {
                ForEach(languages, id: \.self) { language in
                    Text(language)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            Button("Continue") {
                navigateToMainView()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
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
        
        // ✅ Push the new view onto the navigation stack
        DispatchQueue.main.async {
            navigationController.pushViewController(mainViewController, animated: true)
        }
    }
}

struct ViewControllerWrapper: UIViewControllerRepresentable {
    var inputLanguage: String
    var outputLanguage: String

    func makeUIViewController(context: Context) -> ViewController {
        // ✅ Load ViewController from Main.storyboard
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
