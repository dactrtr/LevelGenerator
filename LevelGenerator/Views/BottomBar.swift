import SwiftUI

struct BottomBar: View {
    @Binding var selectedSection: AppSection
    
    // Separar la vista del botón para simplificar
    private func sectionButton(_ section: AppSection) -> some View {
        Button {
            selectedSection = section
        } label: {
            VStack {
                Image(systemName: iconName(for: section))
                    .font(.system(size: 24))
                Text(section.rawValue)
                    .font(.caption)
            }
            .foregroundColor(selectedSection == section ? .accentColor : .gray)
            .frame(maxWidth: .infinity)
        }
    }
    
    // Separar la lógica de los iconos
    private func iconName(for section: AppSection) -> String {
        switch section {
        case .contentManager:
            return "folder"
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            sectionButton(.contentManager)
        }
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}

#Preview {
    BottomBar(selectedSection: .constant(.contentManager))
} 
