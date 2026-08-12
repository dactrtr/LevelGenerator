import SwiftUI

struct CopyButton: View {
    let content: String
    @State private var showingCopiedAlert = false
    
    var body: some View {
        Button {
            copyToClipboard(content)
            showingCopiedAlert = true
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(.borderless)
        .alert("Copied!", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
} 