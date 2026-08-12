import SwiftUI

struct LevelRow: View {
    let level: SavedLevel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(level.name)
                .font(.headline)
            HStack {
                Text("Level \(level.level)")
                Text("•")
                    .foregroundColor(.secondary)
                Text("Room \(level.roomNumber)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ScriptRow: View {
    let script: SavedScript
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(script.name)
                .font(.headline)
            Text("\(script.dialogs.count) dialogs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
} 