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
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel
            VStack {
                AddItemView(selectedItem: $selectedItem,
                           currentX: $currentX,
                           currentY: $currentY,
                           placedItems: $placedItems)
                
                Divider()
                
                ItemListView(placedItems: $placedItems)
            }
            .frame(width: 300)
            .background(Color.gray.opacity(0.1))
            
            // Center Panel
            VStack(alignment: .leading, spacing: 20) {
                RoomInfoView(level: $level,
                           floorNumber: $floorNumber,
                           tile: $tile,
                           light: $light,
                           shadow: $shadow)
                
                MapView(placedItems: placedItems,
                       selectedItem: selectedItem,
                       currentX: currentX,
                       currentY: currentY,
                       selectedEnemy: selectedEnemy,
                       enemyX: enemyX,
                       enemyY: enemyY)
                
                Spacer()
            }
            .padding()
            .frame(width: 400)
            
            // Right Panel
            VStack {
                AddEnemyView(selectedEnemy: $selectedEnemy,
                            enemyX: $enemyX,
                            enemyY: $enemyY,
                            placedItems: $placedItems)
                
                Divider()
                
                EnemyListView(placedItems: $placedItems)
            }
            .frame(width: 300)
            .background(Color.gray.opacity(0.1))
        }
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
