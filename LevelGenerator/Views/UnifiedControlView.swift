import SwiftUI

enum ControlMode: String, CaseIterable {
    case items = "Items"
    case enemies = "Enemies"
}

struct UnifiedControlView: View {
    @Binding var selectedItem: String
    @Binding var selectedEnemy: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var enemyX: Double
    @Binding var enemyY: Double
    @Binding var enemySpeed: Double
    @Binding var placedItems: [PlacedItem]
    @State private var selectedMode: ControlMode = .items
    
    var body: some View {
        VStack(spacing: 16) {
            // Segment Control
            Picker("Mode", selection: $selectedMode) {
                ForEach(ControlMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Content based on selected mode
            if selectedMode == .items {
                VStack(spacing: 0) {
                    AddItemView(
                        selectedItem: $selectedItem,
                        currentX: $currentX,
                        currentY: $currentY,
                        placedItems: $placedItems
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    ItemListView(placedItems: $placedItems)
                }
            } else {
                VStack(spacing: 0) {
                    AddEnemyView(
                        selectedEnemy: $selectedEnemy,
                        enemyX: $enemyX,
                        enemyY: $enemyY,
                        enemySpeed: $enemySpeed,
                        placedItems: $placedItems
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    EnemyListView(placedItems: $placedItems)
                }
            }
        }
        .padding(.top)
        .background(PlatformColor.groupedBackground)
    }
} 