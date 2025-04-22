//
//  TranslationView.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 3/1/25.

import SwiftUI
import Translation

struct TranslationView: View {
    let textToTranslate: String
    let sourceLanguage: Locale.Language
    let targetLanguage: Locale.Language
    let onTranslationComplete: (String) -> Void

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
