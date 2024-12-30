import SwiftUI

struct ExportView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let jsonString = contentStore.exportToJSON() {
                    Text(jsonString)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
            }
            .navigationTitle("Export Data")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
} 