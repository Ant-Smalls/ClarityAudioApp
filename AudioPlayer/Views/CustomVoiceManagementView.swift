import SwiftUI

struct CustomVoiceManagementView: View {
    @StateObject private var viewModel = CustomVoiceViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var newVoiceName = ""
    @State private var newVoiceId = ""
    @State private var editingVoiceName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(viewModel.customVoices) { voice in
                        VoiceRow(voice: voice,
                                isActive: voice.id == viewModel.activeVoice?.id,
                                onActivate: { viewModel.setActiveVoice(voice) },
                                onEdit: {
                                    editingVoiceName = voice.name
                                    viewModel.selectedVoiceForEdit = voice
                                    viewModel.showingEditVoiceSheet = true
                                },
                                onDelete: { viewModel.deleteCustomVoice(voice) })
                    }
                } header: {
                    if !viewModel.customVoices.isEmpty {
                        Text("Saved Voices")
                    }
                }
                
                Section {
                    Button(action: { viewModel.showingAddVoiceSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Voice")
                        }
                    }
                }
            }
            .navigationTitle("Custom Voices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showingAddVoiceSheet) {
                AddVoiceSheet(isPresented: $viewModel.showingAddVoiceSheet,
                             name: $newVoiceName,
                             voiceId: $newVoiceId) {
                    viewModel.addCustomVoice(name: newVoiceName, voiceId: newVoiceId)
                    newVoiceName = ""
                    newVoiceId = ""
                }
            }
            .sheet(isPresented: $viewModel.showingEditVoiceSheet) {
                EditVoiceSheet(isPresented: $viewModel.showingEditVoiceSheet,
                             name: $editingVoiceName) {
                    if let voice = viewModel.selectedVoiceForEdit {
                        viewModel.updateCustomVoice(voice, newName: editingVoiceName)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct VoiceRow: View {
    let voice: CustomVoice
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(voice.name)
                    .font(.headline)
                Text(voice.voiceId)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            Menu {
                Button(action: onActivate) {
                    Label("Set as Active", systemImage: "checkmark.circle")
                }
                Button(action: onEdit) {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onActivate)
    }
}

struct AddVoiceSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var voiceId: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Voice Details")) {
                    TextField("Voice Name", text: $name)
                    TextField("Voice ID", text: $voiceId)
                }
                
                Section {
                    Text("Enter the Voice ID from your ElevenLabs voice clone.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Custom Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(name.isEmpty || voiceId.isEmpty)
                }
            }
        }
    }
}

struct EditVoiceSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Voice Name")) {
                    TextField("Voice Name", text: $name)
                }
            }
            .navigationTitle("Rename Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 