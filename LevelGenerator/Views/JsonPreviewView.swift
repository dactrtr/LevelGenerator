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
    let doorTop: Bool
    let doorRight: Bool
    let doorDown: Bool
    let doorLeft: Bool
    let doorTopLeadsTo: Int
    let doorRightLeadsTo: Int
    let doorDownLeadsTo: Int
    let doorLeftLeadsTo: Int
    let comic: Bool
    let comicName: String
    let comicEnter: Bool
    let onReset: () -> Void
    @State private var showCopiedAlert = false
    
    
    private func assignMissingPropIds() -> [PlacedItem] {
        var updatedItems = placedItems
        for i in 0..<updatedItems.count {
            if updatedItems[i].itemType == .prop && updatedItems[i].propId == nil {
                updatedItems[i].propId = UUID().uuidString
            }
        }
        return updatedItems
    }
    
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
                        Text("Copy level")
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
        let updatedItems = assignMissingPropIds()
        let propItems = updatedItems.filter { $0.itemType == .prop }
        let enemyItems = placedItems.filter { $0.itemType == .enemy }
        let triggerItems = placedItems.filter { $0.itemType == .trigger }
        let gameItems = placedItems.filter { $0.itemType == .item }
        
        let propsJson = propItems.map { item in
            """
                    {
                        type = "\(item.type)",
                        x = \(Int(item.x)),
                        y = \(Int(item.y))\(item.nocollide ? ",\n                    nocollide = true" : ""),
                        id = \"\(item.propId!)\"
                    }
            """
        }.joined(separator: ",\n")
        
        let enemiesJson = enemyItems.map { item in
            """
                    {
                        name = "\(item.type)",
                        x = \(Int(item.x)),
                        y = \(Int(item.y)),
                        speed = \(item.speed ?? 1.0),
                        id = \"\(item.enemyId!)\"
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
                        script = "\(item.script ?? "")"\(item.triggerType == "cutscene" ? ",\n                    type = \"cutscene\"" : "")
                    }
            """
        }.joined(separator: ",\n")
        
        let itemsJson = gameItems.map { item in
            """
                    {
                        type = '\(item.type)',
                        x = \(Int(item.x)),
                        y = \(Int(item.y))\(item.type == "crewmember" ? ",\n  taken = false" : "")\(item.crewId != nil ? ",\n  crewId = \"\(item.crewId!)\"" : "")
                    }
            """
        }.joined(separator: ",\n")
        
        let doorsJson = [
            (direction: "top", isOpen: doorTop, leadsTo: doorTopLeadsTo),
            (direction: "right", isOpen: doorRight, leadsTo: doorRightLeadsTo),
            (direction: "down", isOpen: doorDown, leadsTo: doorDownLeadsTo),
            (direction: "left", isOpen: doorLeft, leadsTo: doorLeftLeadsTo)
        ]
        .filter { $0.isOpen }
        .map { door in
            """
                    {
                        direction = '\(door.direction)',
                        open = 'open',
                        leadsTo = \(level * 100 + door.leadsTo)
                    }
            """
        }
        .joined(separator: ",\n")
        
        return """
        {
            floor = {
                level = \(level),
                visited = false,
                roomNumber = \(floorNumber),
                tile = \(tile),
                light = \(String(format: "%.1f", light)),
                shadow = \(shadow),
                doors = {
        \(doorsJson)
                },
        
                comic = {
        \(comic ? """
                        wasPlayed = false,
                        name = "\(comicName)"\(comicEnter ? ",\n play = \"enter\"" : ",\n   play = nil")
                """ : "") 
                },
                items = {
        \(itemsJson)
                },
                triggers = {
        \(triggersJson)
                },
                enemies = {
        \(enemiesJson)
                },
                props = {
        \(propsJson)
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
