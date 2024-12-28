//
//  ContentView.swift
//  LevelGenerator
//
//  Created by Dactrtr on 2024/12/28.
//

import SwiftUI

struct ContentView: View {
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
    
    @State private var placedItems: [PlacedItem] = []
    @State private var enemySpeed: Double = 1.0
    
    var body: some View {
        #if os(iOS)
        content
        #else
        content
        #endif
    }
    
    var content: some View {
        HStack(spacing: 0) {
            // Left Panel
            VStack(spacing: 0) {
                AddItemView(selectedItem: $selectedItem,
                           currentX: $currentX,
                           currentY: $currentY,
                           placedItems: $placedItems)
                
                Divider()
                    .padding(.vertical, 8)
                
                ItemListView(placedItems: $placedItems)
            }
            .frame(width: 300)
            .background(PlatformColor.groupedBackground)
            
            // Center Panel
            VStack(alignment: .center, spacing: 16) {
                RoomInfoView(level: $level,
                           floorNumber: $floorNumber,
                           tile: $tile,
                           light: $light,
                           shadow: $shadow)
                    .background(PlatformColor.secondaryBackground)
                    .cornerRadius(10)
                
                MapView(placedItems: placedItems,
                       selectedItem: selectedItem,
                       currentX: currentX,
                       currentY: currentY,
                       selectedEnemy: selectedEnemy,
                       enemyX: enemyX,
                       enemyY: enemyY)
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
                    onReset: {
                        level = 1
                        floorNumber = 1
                        tile = 1
                        light = 0.5
                        shadow = false
                        placedItems.removeAll()
                    }
                )
                .cornerRadius(10)
                .frame(maxHeight: .infinity)
            }
            .padding()
            .background(PlatformColor.background)
            
            // Right Panel
            UnifiedControlView(
                selectedItem: $selectedItem,
                selectedEnemy: $selectedEnemy,
                currentX: $currentX,
                currentY: $currentY,
                enemyX: $enemyX,
                enemyY: $enemyY,
                enemySpeed: $enemySpeed,
                placedItems: $placedItems
            )
            .frame(width: 300)
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Level Generator")
        #endif
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
