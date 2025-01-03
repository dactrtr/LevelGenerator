import SwiftUI

struct LevelEditorView: View, LevelEditorState {
    @Binding var level: SavedLevel
    @Environment(\.dismiss) var dismiss
    
    @State internal var currentLevel: Int
    @State internal var floorNumber: Int
    @State internal var tile: Int
    @State internal var light: Double
    @State internal var shadow: Bool
    
    @State private var currentX: Double = 200
    @State private var currentY: Double = 120
    @State private var selectedItem: String = "chair"
    
    @State private var enemyX: Double = 200
    @State private var enemyY: Double = 120
    @State private var selectedEnemy: String = "brocorat"
    @State private var enemySpeed: Double = 1.0
    
    @State private var triggerX: Double = 200
    @State private var triggerY: Double = 120
    
    @State internal var placedItems: [PlacedItem]
    
    @State private var selectedMode: ControlMode = .props
    
    @State private var triggerWidth: Double = 60
    @State private var triggerHeight: Double = 30
    
    @State internal var doorTop: Bool
    @State internal var doorRight: Bool
    @State internal var doorDown: Bool
    @State internal var doorLeft: Bool
    
    @State internal var doorTopLeadsTo: Int
    @State internal var doorRightLeadsTo: Int
    @State internal var doorDownLeadsTo: Int
    @State internal var doorLeftLeadsTo: Int
    
    init(level: Binding<SavedLevel>) {
        self._level = level
        // Inicializar los estados con los valores del nivel
        _currentLevel = State(initialValue: level.wrappedValue.level)
        _floorNumber = State(initialValue: level.wrappedValue.roomNumber)
        _tile = State(initialValue: level.wrappedValue.tile)
        _light = State(initialValue: level.wrappedValue.light)
        _shadow = State(initialValue: level.wrappedValue.shadow)
        _placedItems = State(initialValue: level.wrappedValue.placedItems)
        _doorTop = State(initialValue: level.wrappedValue.doors.top)
        _doorRight = State(initialValue: level.wrappedValue.doors.right)
        _doorDown = State(initialValue: level.wrappedValue.doors.down)
        _doorLeft = State(initialValue: level.wrappedValue.doors.left)
        _doorTopLeadsTo = State(initialValue: level.wrappedValue.doors.topLeadsTo)
        _doorRightLeadsTo = State(initialValue: level.wrappedValue.doors.rightLeadsTo)
        _doorDownLeadsTo = State(initialValue: level.wrappedValue.doors.downLeadsTo)
        _doorLeftLeadsTo = State(initialValue: level.wrappedValue.doors.leftLeadsTo)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Center Panel - Map and Room Info side by side
            HStack(alignment: .top, spacing: 8) {
                VStack {
                    MapView(
                        placedItems: placedItems,
                        selectedItem: selectedItem,
                        currentX: currentX,
                        currentY: currentY,
                        selectedEnemy: selectedEnemy,
                        enemyX: enemyX,
                        enemyY: enemyY,
                        showTriggerPreview: selectedMode == .triggers,
                        triggerX: triggerX,
                        triggerY: triggerY,
                        triggerWidth: triggerWidth,
                        triggerHeight: triggerHeight,
                        doorTop: doorTop,
                        doorRight: doorRight,
                        doorDown: doorDown,
                        doorLeft: doorLeft,
                        doorTopLeadsTo: doorTopLeadsTo,
                        doorRightLeadsTo: doorRightLeadsTo,
                        doorDownLeadsTo: doorDownLeadsTo,
                        doorLeftLeadsTo: doorLeftLeadsTo,
                        level: currentLevel
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    JsonPreviewView(
                        level: currentLevel,
                        floorNumber: floorNumber,
                        tile: tile,
                        light: light,
                        shadow: shadow,
                        placedItems: placedItems,
                        doorTop: doorTop,
                        doorRight: doorRight,
                        doorDown: doorDown,
                        doorLeft: doorLeft,
                        doorTopLeadsTo: doorTopLeadsTo,
                        doorRightLeadsTo: doorRightLeadsTo,
                        doorDownLeadsTo: doorDownLeadsTo,
                        doorLeftLeadsTo: doorLeftLeadsTo,
                        onReset: {
                            currentLevel = 1
                            floorNumber = 1
                            tile = 1
                            light = 0.5
                            shadow = false
                            placedItems.removeAll()
                        }
                    )
                    .frame(maxHeight: .infinity)
                    .padding()
                    .background(PlatformColor.background)
                }
                
                RoomInfoView(
                    level: $currentLevel,
                    floorNumber: $floorNumber,
                    tile: $tile,
                    light: $light,
                    shadow: $shadow,
                    doorTop: $doorTop,
                    doorRight: $doorRight,
                    doorDown: $doorDown,
                    doorLeft: $doorLeft,
                    doorTopLeadsTo: $doorTopLeadsTo,
                    doorRightLeadsTo: $doorRightLeadsTo,
                    doorDownLeadsTo: $doorDownLeadsTo,
                    doorLeftLeadsTo: $doorLeftLeadsTo
                )
                .background(PlatformColor.secondaryBackground)
                .cornerRadius(10)
                .frame(width: 300)
            }
            .padding()
            .background(PlatformColor.background)
            
            // Right Panel - Controls
            UnifiedControlView(
                selectedItem: $selectedItem,
                selectedEnemy: $selectedEnemy,
                currentX: $currentX,
                currentY: $currentY,
                enemyX: $enemyX,
                enemyY: $enemyY,
                enemySpeed: $enemySpeed,
                placedItems: $placedItems,
                triggerX: $triggerX,
                triggerY: $triggerY,
                selectedMode: $selectedMode,
                triggerWidth: $triggerWidth,
                triggerHeight: $triggerHeight
            )
            .frame(width: 300)
        }
        .frame(maxHeight: .infinity)
        .navigationTitle(level.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    var updatedLevel = level
                    updatedLevel.update(with: self)
                    level = updatedLevel
                    dismiss()
                }
            }
        }
    }
} 