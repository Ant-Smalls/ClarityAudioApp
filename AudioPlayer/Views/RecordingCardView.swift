import SwiftUI
import AVFoundation

struct RecordingCardView: View {
    let session: RecordingSession
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(formatDate(session.dateCreated))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 16) {
                // Play/Pause Button
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Language indicators
                    HStack {
                        Text(session.sourceLanguage)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#40607e"))
                            .cornerRadius(4)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(session.targetLanguage)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#584d78"))
                            .cornerRadius(4)
                    }
                    
                    // Duration
                    Text(formatDuration(session.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { showingDetails = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#23252c"))
        .cornerRadius(12)
        .shadow(radius: 5)
        .sheet(isPresented: $showingDetails) {
            RecordingDetailView(session: session)
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        do {
            let audioURL = try AudioFileManager.shared.loadAudioFile(fileName: session.audioFileName)
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = AVPlayerDelegate(onComplete: {
                self.isPlaying = false
            })
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("❌ Error playing audio: \(error)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
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

// Helper class for audio player delegate
class AVPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onComplete()
    }
} 