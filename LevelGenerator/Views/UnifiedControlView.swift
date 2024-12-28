import SwiftUI

enum ControlMode: String, CaseIterable {
    case items = "Items"
    case enemies = "Enemies"
    case triggers = "Triggers"
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
    @Binding var triggerX: Double
    @Binding var triggerY: Double
    @Binding var selectedMode: ControlMode
    @Binding var triggerWidth: Double
    @Binding var triggerHeight: Double
    
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
            switch selectedMode {
            case .items:
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
            case .enemies:
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
            case .triggers:
                VStack(spacing: 0) {
                    AddTriggerView(
                        currentX: $triggerX,
                        currentY: $triggerY,
                        placedItems: $placedItems,
                        previewWidth: $triggerWidth,
                        previewHeight: $triggerHeight
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    TriggerListView(placedItems: $placedItems)
                }
            }
        }
        .padding(.top)
        .background(PlatformColor.groupedBackground)
    }
} 