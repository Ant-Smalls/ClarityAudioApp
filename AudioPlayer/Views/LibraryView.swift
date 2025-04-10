import SwiftUI
import AVFoundation

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
                if viewModel.recordings.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "waveform")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Recordings Yet")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Your recordings will appear here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                } else {
                    // Recordings list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.recordings) { recording in
                                RecordingCell(recording: recording) {
                                    viewModel.deleteRecording(recording)
                                }
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
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                        .padding(8)
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
                Text(recording.sourceLanguage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(recording.targetLanguage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
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
} 