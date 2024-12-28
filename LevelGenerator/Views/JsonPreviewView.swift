import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct JsonPreviewView: View {
    let level: Int
    let floorNumber: Int
    let tile: Int
    let light: Double
    let shadow: Bool
    let placedItems: [PlacedItem]
    var onReset: () -> Void
    
    @State private var showCopiedAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                Text(generateJson())
                    .font(.system(size: 11, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.05))
            
            // Botones
            HStack(spacing: 20) {
                Button(action: {
                    onReset()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset Level")
                    }
                    .foregroundColor(.red)
                }
                
                Button(action: {
                    copyToClipboard()
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy JSON")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 8)
        }
        .alert("JSON Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = generateJson()
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generateJson(), forType: .string)
        #endif
        showCopiedAlert = true
    }
    
    private func generateJson() -> String {
        """
        --\(floorNumber)
        {
            floor = {
                level = \(level),
                visited = false,
                floorNumber = \(floorNumber),
                tile = \(tile),
                light = \(String(format: "%.1f", light)),
                shadow = \(shadow),
                comic = {},
                triggers = {},
                enemies = {
        \(generateEnemiesSection())
                },
                doors = {},
                items = {},
                props = {
        \(generatePropsSection())
                }
            }
        }
        """
    }
    
    private func generateEnemiesSection() -> String {
        let enemies = placedItems.filter { $0.itemType == .enemy }
        if enemies.isEmpty {
            return ""
        }
        
        return enemies.map { enemy in
            """
                    {
                        name = "\(enemy.type)",
                        x = \(Int(enemy.x)),
                        y = \(Int(enemy.y)),
                        speed = \(String(format: "%.1f", enemy.speed ?? 1.0))
                    }
            """
        }.joined(separator: ",\n")
    }
    
    private func generatePropsSection() -> String {
        let props = placedItems.filter { $0.itemType == .furniture }
        if props.isEmpty {
            return ""
        }
        
        return props.map { prop in
            if prop.nocollide {
                """
                        {
                            type = '\(prop.type)',
                            x = \(Int(prop.x)),
                            y = \(Int(prop.y)),
                            nocollide = true
                        }
                """
            } else {
                """
                        {
                            type = '\(prop.type)',
                            x = \(Int(prop.x)),
                            y = \(Int(prop.y))
                        }
                """
            }
        }.joined(separator: ",\n")
    }
} 