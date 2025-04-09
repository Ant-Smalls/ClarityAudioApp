//
//  TranslationView.swift
//  AudioPlayer
//
//  Created by Anthony Smaldore on 3/1/25.

import SwiftUI

struct TranslationView: View {
    let sourceText: String
    let sourceLanguage: String
    let targetLanguage: String
    let onComplete: (String) -> Void
    
    @State private var isTranslating = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background color
            AppTheme.backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Source text section
                VStack(alignment: .leading, spacing: 8) {
                    Label("Original Text", systemImage: "text.quote")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(sourceText)
                        .font(.body)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.secondaryColor)
                        .cornerRadius(8)
                }
                
                if isTranslating {
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Simulate translation with a simple delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // For now, just return a placeholder translation
                let translatedText = "Translation placeholder: \(sourceText)"
                isTranslating = false
                onComplete(translatedText)
                dismiss()
            }
        }
    }
}
