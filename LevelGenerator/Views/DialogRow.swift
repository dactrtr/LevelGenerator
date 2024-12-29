import SwiftUI

struct DialogRow: View {
    let image: String
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(image)
                .resizable()
                .frame(width: 118, height: 94)
            
            Text(text)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
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