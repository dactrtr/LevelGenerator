//
//  ContentView.swift
//  LevelGenerator
//
//  Created by Dactrtr on 2024/12/28.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedSection: AppSection = .levelEditor
    @State private var level: Int = 1
    @State private var floorNumber: Int = 1
    @State private var tile: Int = 1
    @State private var light: Double = 0.5
    @State private var shadow: Bool = false
    
    @State private var currentX: Double = 200
    @State private var currentY: Double = 120
    @State private var selectedItem: String = "chair"
    
    @State private var enemyX: Double = 200
    @State private var enemyY: Double = 120
    @State private var selectedEnemy: String = "brocorat"
    @State private var enemySpeed: Double = 1.0
    
    // Nuevas variables de estado para triggers
    @State private var triggerX: Double = 200
    @State private var triggerY: Double = 120
    
    @State private var placedItems: [PlacedItem] = []
    
    @State private var selectedMode: ControlMode = .items
    
    @State private var triggerWidth: Double = 60
    @State private var triggerHeight: Double = 30
    
    // Estados para las puertas
    @State private var doorTop: Bool = false
    @State private var doorRight: Bool = false
    @State private var doorDown: Bool = false
    @State private var doorLeft: Bool = false
    
    @State private var doorTopLeadsTo: Int = 1
    @State private var doorRightLeadsTo: Int = 1
    @State private var doorDownLeadsTo: Int = 1
    @State private var doorLeftLeadsTo: Int = 1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Contenido principal
                switch selectedSection {
                case .levelEditor:
                    content
                case .script:
                    ScriptView()
                }
                
                // Bottom Bar
                HStack {
                    ForEach(AppSection.allCases, id: \.self) { section in
                        Button(action: {
                            selectedSection = section
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: section == .levelEditor ? "square.grid.2x2" : "doc.text")
                                    .font(.system(size: 20))
                                Text(section.rawValue)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedSection == section ? .blue : .gray)
                    }
                }
                .padding(.vertical, 8)
                .background(PlatformColor.secondaryBackground)
            }
            .navigationTitle(selectedSection.rawValue)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
    
    var content: some View {
        HStack(spacing: 0) {
            
                // Center Panel - Map and Room Info side by side
                HStack(alignment: .top, spacing: 8) {
                    VStack{
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
                            floorNumber: floorNumber
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        
                        JsonPreviewView(
                            level: level,
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
                                level = 1
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
                        level: $level,
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
        .frame(maxHeight:.infinity)
    }
       
}

// Añadir esta estructura para manejar las preferencias del rectángulo
struct RectPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
}
