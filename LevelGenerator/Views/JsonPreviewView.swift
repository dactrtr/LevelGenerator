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
    let onReset: () -> Void
    @State private var showCopiedAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text(generateJson())
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
            }
            
            HStack {
                Button(action: onReset) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .foregroundColor(.red)
                }
                
                Spacer()
                
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
    
    private func generateJson() -> String {
        let furnitureItems = placedItems.filter { $0.itemType == .furniture }
        let enemyItems = placedItems.filter { $0.itemType == .enemy }
        let triggerItems = placedItems.filter { $0.itemType == .trigger }
        
        let furnitureJson = furnitureItems.map { item in
            """
                    {
                        type = "\(item.type)",
                        x = \(Int(item.x)),
                        y = \(Int(item.y)),
                        nocollide = \(item.nocollide)
                    }
            """
        }.joined(separator: ",\n")
        
        let enemiesJson = enemyItems.map { item in
            """
                    {
                        type = "\(item.type)",
                        x = \(Int(item.x)),
                        y = \(Int(item.y)),
                        speed = \(item.speed ?? 1.0)
                    }
            """
        }.joined(separator: ",\n")
        
        let triggersJson = triggerItems.map { item in
            """
                    {
                        usedTrigger = false,
                        x = \(Int(item.x)),
                        y = \(Int(item.y)),
                        width = \(Int(item.width ?? 60)),
                        height = \(Int(item.height ?? 30)),
                        script = \(item.script ?? 1)
                    }
            """
        }.joined(separator: ",\n")
        
        return """
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
                triggers = {
        \(triggersJson)
                },
                enemies = {
        \(enemiesJson)
                },
                items = {
        \(furnitureJson)
                }
            }
        }
        """
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
} 