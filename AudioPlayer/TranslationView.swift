// TranslationView.swift
// AudioPlayer
// Created by Yusuke Abe, Tadija Ciric, Anthony Smaldore on 3/1/25.
///
// A SwiftUI view used for performing background translation asynchronously
// using the system Translation framework. It accepts text input, source and target
// languages, and returns the translated result via callback..

import SwiftUI
import Translation

// Invisible SwiftUI view that performs translation using Apple's Translation framework.
// The translation is initiated as soon as the view appears and cancelled when it disappears.
struct TranslationView: View {
    let textToTranslate: String
    let sourceLanguage: Locale.Language
    let targetLanguage: Locale.Language
    // Completion handler to receive the translated string.
    let onTranslationComplete: (String) -> Void
    
    // Stores the current translation task to allow cancellation.
    @State private var translationTask: Task<Void, Never>? // For task cancellation.
    
    

    var body: some View {
        // An invisible view that triggers translation in the background.
        Color.clear
            .translationTask(source: sourceLanguage, target: targetLanguage) { session in
                translationTask = Task {
                    do {
                        // Perform translation asynchronously.
                        let response = try await session.translate(textToTranslate)
                        DispatchQueue.main.async {
                            onTranslationComplete(response.targetText)
                        }
                    } catch {
                        print("❌ Translation failed:", error)
                    }
                }
            }
            .onDisappear {
                // Cancel any ongoing task when this view goes away.
                translationTask?.cancel()
                translationTask = nil
            }
    }
}
