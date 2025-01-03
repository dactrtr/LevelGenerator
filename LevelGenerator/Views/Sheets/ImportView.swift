import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var isPresented: Bool
    @Binding var importText: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @State private var showingFileImporter = false
    @State private var importMode: ImportMode = .replace
    
    enum ImportMode {
        case replace, merge
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Import Mode", selection: $importMode) {
                    Text("Replace").tag(ImportMode.replace)
                    Text("Merge").tag(ImportMode.merge)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TextEditor(text: $importText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                
                VStack(spacing: 16) {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Load from File", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                    
                    Button {
                        #if os(iOS)
                        if let clipboardString = UIPasteboard.general.string {
                            importText = clipboardString
                        }
                        #else
                        if let clipboardString = NSPasteboard.general.string(forType: .string) {
                            importText = clipboardString
                        }
                        #endif
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        let success = importMode == .replace ?
                            contentStore.importFromJSON(importText) :
                            contentStore.mergeFromJSON(importText)
                        
                        alertMessage = success ? "Import successful" : "Import failed"
                        showingAlert = true
                        
                        if success {
                            isPresented = false
                        }
                    } label: {
                        Text("Import")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(importText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Import Data")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let selectedFile = files.first else { return }
                    
                    do {
                        let data = try Data(contentsOf: selectedFile)
                        if let content = String(data: data, encoding: .utf8) {
                            importText = content
                        }
                    } catch {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                    
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
} 