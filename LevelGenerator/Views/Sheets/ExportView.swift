import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var isPresented: Bool
    @State private var showingExportDialog = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if let jsonString = contentStore.exportToJSON() {
                    ScrollView {
                        Text(jsonString)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            #if os(iOS)
                            UIPasteboard.general.string = jsonString
                            #else
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(jsonString, forType: .string)
                            #endif
                        } label: {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showingExportDialog = true
                        } label: {
                            Label("Save as File", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(true)
                    }
                    .padding()
                }
            }
            .navigationTitle("Export Data")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .fileExporter(
                isPresented: $showingExportDialog,
                document: TextFileDocument(text: contentStore.exportToJSON() ?? ""),
                contentType: .plainText,
                defaultFilename: "level_generator_export.txt"
            ) { result in
                switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
} 