import SwiftUI

struct Recording: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let duration: TimeInterval
    let sourceLanguage: String
    let targetLanguage: String
    let audioURL: URL
}

struct LibraryView: View {
    @State private var recordings: [Recording] = []
    @State private var selectedRecording: Recording?
    @State private var showingPlayer = false
    
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
                // Header
                Text("Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                if recordings.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "waveform")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Recordings Yet")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Your saved recordings will appear here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    // Recordings list
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(recordings) { recording in
                                RecordingCell(recording: recording)
                                    .onTapGesture {
                                        selectedRecording = recording
                                        showingPlayer = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPlayer) {
            if let recording = selectedRecording {
                PlayerView(recording: recording)
            }
        }
        .onAppear {
            loadRecordings()
        }
    }
    
    private func loadRecordings() {
        // TODO: Implement loading recordings from storage
        // This is a placeholder implementation
        recordings = []
    }
}

struct RecordingCell: View {
    let recording: Recording
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(recording.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text(formatDate(recording.date))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatDuration(recording.duration))
                        .font(.subheadline)
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
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title)
                .foregroundColor(AppTheme.accentColor)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlayerView: View {
    let recording: Recording
    @Environment(\.presentationMode) var presentationMode
    @State private var isPlaying = false
    @State private var progress: Double = 0
    
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
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Waveform visualization placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .padding(.horizontal)
                
                // Title and metadata
                VStack(spacing: 10) {
                    Text(recording.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(recording.sourceLanguage) → \(recording.targetLanguage)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Progress slider
                Slider(value: $progress, in: 0...1)
                    .accentColor(AppTheme.accentColor)
                    .padding(.horizontal)
                
                // Time labels
                HStack {
                    Text(formatTime(progress * recording.duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(formatTime(recording.duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                
                // Playback controls
                HStack(spacing: 40) {
                    Button(action: {
                        // Skip backward
                    }) {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    Button(action: {
                        // Skip forward
                    }) {
                        Image(systemName: "goforward.15")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 