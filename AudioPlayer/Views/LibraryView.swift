import SwiftUI

class LibraryViewModel: ObservableObject {
    @Published var recordings: [RecordingSession] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func loadRecordings() {
        isLoading = true
        do {
            recordings = try DatabaseManager.shared.getAllRecordingSessions()
            isLoading = false
        } catch {
            errorMessage = "Failed to load recordings: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func deleteRecording(_ session: RecordingSession) {
        do {
            // Delete from database
            try DatabaseManager.shared.deleteRecordingSession(id: session.id)
            // Delete audio file
            try AudioFileManager.shared.deleteAudioFile(fileName: session.audioFileName)
            // Update UI
            if let index = recordings.firstIndex(where: { $0.id == session.id }) {
                recordings.remove(at: index)
            }
        } catch {
            errorMessage = "Failed to delete recording: \(error.localizedDescription)"
        }
    }
}

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var searchText = ""
    
    var filteredRecordings: [RecordingSession] {
        if searchText.isEmpty {
            return viewModel.recordings
        }
        return viewModel.recordings.filter { recording in
            recording.name.localizedCaseInsensitiveContains(searchText) ||
            recording.transcription.localizedCaseInsensitiveContains(searchText) ||
            recording.translation.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#23252c")
                    .edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if viewModel.recordings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "mic.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No recordings yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredRecordings, id: \.id) { session in
                                RecordingCardView(session: session)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteRecording(session)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search recordings")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onAppear {
            viewModel.loadRecordings()
        }
    }
} 