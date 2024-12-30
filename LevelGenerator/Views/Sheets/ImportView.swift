import SwiftUI

struct ImportView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var isPresented: Bool
    @Binding var importText: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $importText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                
                HStack {
                    Button("Import and Replace") {
                        if contentStore.importFromJSON(importText) {
                            isPresented = false
                            importText = ""
                        } else {
                            alertMessage = "Invalid data format"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Import and Merge") {
                        if contentStore.mergeFromJSON(importText) {
                            isPresented = false
                            importText = ""
                        } else {
                            alertMessage = "Invalid data format"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Import Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        importText = ""
                    }
                }
            }
            .alert("Import Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
} 