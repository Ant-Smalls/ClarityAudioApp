//
//  TranslationView.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 3/1/25.
//

import SwiftUI
import Translation

struct TranslationView: View {
    let textToTranslate: String
    let sourceLanguage: Locale.Language
    let targetLanguage: Locale.Language
    let onTranslationComplete: (String) -> Void

    @State private var translatedText: String = ""
    @State private var isViewActive = true
    @State private var translationTask: Task<Void, Never>? // ✅ Track the task to cancel it

    var body: some View {
        Text(textToTranslate)
            .translationTask(source: sourceLanguage,
                             target: targetLanguage) { session in
                translationTask = Task {
                    do {
                        if isViewActive {
                            let response = try await session.translate(textToTranslate)
                            DispatchQueue.main.async {
                                translatedText = response.targetText
                                onTranslationComplete(response.targetText)
                            }
                        }
                    } catch {
                        print("❌ Translation failed:", error)
                    }
                }
            }
            .onDisappear {
                print("⚠️ Cancelling translation because view is disappearing")
                isViewActive = false
                translationTask?.cancel() // ✅ Force stop translation before crash
                translationTask = nil
            }
    }
}

