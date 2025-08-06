import SwiftUI
import AVFoundation

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showFavoritesOnly = false
    
    var filteredRecordings: [RecordingSession] {
        if showFavoritesOnly {
            return viewModel.recordings.filter { $0.isFavorite }
        }
        return viewModel.recordings
    }
    
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
            
            VStack {
                // Filter toggle
                Toggle(isOn: $showFavoritesOnly) {
                    Label("Show Favorites Only", systemImage: "star.fill")
                        .foregroundColor(.white)
                }
                .padding()
                .tint(.yellow)
                
                if filteredRecordings.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "waveform")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(showFavoritesOnly ? "No Favorite Recordings" : "No Recordings Yet")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(showFavoritesOnly ? "Your favorite recordings will appear here" : "Your recordings will appear here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                } else {
                    // Recordings list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecordings) { recording in
                                RecordingCell(recording: recording,
                                            onDelete: {
                                    viewModel.deleteRecording(recording)
                                },
                                            onToggleFavorite: {
                                    viewModel.toggleFavorite(recording)
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadRecordings()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// Recording cell view
struct RecordingCell: View {
    let recording: RecordingSession
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    @State private var isExpanded = false
    @State private var showingDeleteAlert = false
    @State private var showingCopiedToast = false
    @State private var copiedText = ""
    
    // Language display names
    private let languageDisplayNames: [String: String] = [
        "en-US": "English",
        "en": "English",
        "es": "Spanish",
        "de": "German",
        "pt-BR": "Portuguese",
        "pt": "Portuguese",
        "ja": "Japanese",
        "fr": "French",
        "it": "Italian",
        "ru": "Russian",
        "ko": "Korean"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header section (always visible)
            HStack {
                Button(action: { withAnimation(.spring()) { isExpanded.toggle() }}) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(recording.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if recording.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.subheadline)
                            }
                        }
                        
                        HStack {
                            Label(formatDuration(recording.duration), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text(formatDate(recording.dateCreated))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        HStack {
                            // Get base language code without region (e.g., "en" from "en-US")
                            let sourceBase = recording.sourceLanguage.split(separator: "-").first.map(String.init) ?? recording.sourceLanguage
                            let targetBase = recording.targetLanguage.split(separator: "-").first.map(String.init) ?? recording.targetLanguage
                            
                            Text(languageDisplayNames[sourceBase] ?? sourceBase)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(languageDisplayNames[targetBase] ?? targetBase)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: recording.isFavorite ? "star.fill" : "star")
                        .foregroundColor(recording.isFavorite ? .yellow : .white.opacity(0.7))
                        .font(.title3)
                }
                .padding(.horizontal, 8)
                
                Button(action: { withAnimation(.spring()) { isExpanded.toggle() }}) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 8)
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Transcription section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Transcription")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = recording.transcription
                                copiedText = "Transcription"
                                showCopiedToast()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Text(recording.transcription)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // Translation section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Translation")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = recording.translation
                                copiedText = "Translation"
                                showCopiedToast()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Text(recording.translation)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // Action buttons
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 12)
                .overlay(
                    // Toast overlay
                    Group {
                        if showingCopiedToast {
                            VStack {
                                Text("\(copiedText) copied to clipboard")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .transition(.opacity)
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .animation(.spring(), value: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
        .alert("Delete Recording", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this recording? This action cannot be undone.")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func showCopiedToast() {
        withAnimation {
            showingCopiedToast = true
        }
        // Hide the toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopiedToast = false
            }
        }
    }
}

// ViewModel
class LibraryViewModel: ObservableObject {
    @Published var recordings: [RecordingSession] = []
    @Published var isLoading = false
    
    func loadRecordings() {
        isLoading = true
        
        do {
            recordings = try DatabaseManager.shared.getAllRecordings(sortBy: .dateCreated)
        } catch {
            print("❌ Failed to load recordings:", error)
        }
        
        isLoading = false
    }
    
    func deleteRecording(_ recording: RecordingSession) {
        do {
            try DatabaseManager.shared.deleteRecordingSession(id: recording.id)
            if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                recordings.remove(at: index)
            }
        } catch {
            print("❌ Failed to delete recording:", error)
        }
    }
    
    func toggleFavorite(_ recording: RecordingSession) {
        do {
            try DatabaseManager.shared.toggleFavorite(for: recording.id)
            // Update the local state
            if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                recordings[index].isFavorite.toggle()
            }
        } catch {
            print("❌ Failed to toggle favorite:", error)
        }
    }
} 