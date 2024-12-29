import SwiftUI

struct BottomBar: View {
    @Binding var selectedSection: AppSection
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Bar Content
            if isExpanded {
                HStack(spacing: 0) {
                    ForEach(AppSection.allCases, id: \.self) { section in
                        Button(action: {
                            selectedSection = section
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: section == .levelEditor ? "square.grid.2x2" : "doc.text.fill")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.hierarchical)
                                    .contentTransition(.symbolEffect(.replace))
                                Text(section.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedSection == section ? .blue : .gray.opacity(0.7))
                    }
                }
            }
        }
        .frame(width: 200)
        .frame(height: isExpanded ? 82 : 20)
        .background(
            PlatformColor.secondaryBackground
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
} 
