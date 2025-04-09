import SwiftUI

struct RecordingDetailView: View {
    let session: RecordingSession
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Transcription Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Transcription", systemImage: "text.bubble")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(session.transcription)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#40607e"))
                            .cornerRadius(8)
                    }
                    
                    // Translation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Translation", systemImage: "globe")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(session.translation)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#584d78"))
                            .cornerRadius(8)
                    }
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Details", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DetailRow(title: "Created", value: formatDate(session.dateCreated))
                        DetailRow(title: "Duration", value: formatDuration(session.duration))
                        DetailRow(title: "Source Language", value: session.sourceLanguage)
                        DetailRow(title: "Target Language", value: session.targetLanguage)
                    }
                }
                .padding()
            }
            .background(Color(hex: "#23252c").edgesIgnoringSafeArea(.all))
            .navigationTitle(session.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.subheadline)
    }
} 