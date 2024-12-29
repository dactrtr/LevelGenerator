import SwiftUI

struct DialogRow: View {
    let image: String
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(image)
                .resizable()
                .frame(width: 32, height: 32)
            
            Text(text)
                .lineLimit(3)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(PlatformColor.secondaryBackground)
        .cornerRadius(8)
    }
} 