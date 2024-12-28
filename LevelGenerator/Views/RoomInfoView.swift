import SwiftUI

struct RoomInfoView: View {
    @Binding var level: Int
    @Binding var floorNumber: Int
    @Binding var tile: Int
    @Binding var light: Double
    @Binding var shadow: Bool
    
    var body: some View {
        Group {
            Text("Información del cuarto")
                .font(.headline)
            
            HStack {
                Text("Level:")
                Stepper(value: $level, in: 1...100) {
                    Text("\(level)")
                }
            }
            
            HStack {
                Text("Floor Number:")
                Stepper(value: $floorNumber, in: 1...10) {
                    Text("\(floorNumber)")
                }
            }
            
            HStack {
                Text("Tile:")
                Stepper(value: $tile, in: 1...20) {
                    Text("\(tile)")
                }
            }
            
            HStack {
                Text("Light:")
                Slider(value: $light)
            }
            
            Toggle("Shadow", isOn: $shadow)
        }
        .padding()
    }
} 