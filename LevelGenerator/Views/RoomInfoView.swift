import SwiftUI

struct RoomInfoView: View {
    @Binding var level: Int
    @Binding var floorNumber: Int
    @Binding var tile: Int
    @Binding var light: Double
    @Binding var shadow: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Room Information")
                .font(.headline)
            
            HStack {
                // Primera columna
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Level:")
                            .frame(width: 45, alignment: .leading)
                        Stepper(value: $level, in: 1...100) {
                            Text("\(level)")
                        }
                    }
                    
                    HStack {
                        Text("Floor:")
                            .frame(width: 45, alignment: .leading)
                        Stepper(value: $floorNumber, in: 1...10) {
                            Text("\(floorNumber)")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Segunda columna
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tile:")
                            .frame(width: 35, alignment: .leading)
                        Stepper(value: $tile, in: 1...20) {
                            Text("\(tile)")
                        }
                    }
                    
                    HStack {
                        Text("Light:")
                            .frame(width: 35, alignment: .leading)
                        Slider(value: $light)
                            .frame(width: 80)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Tercera columna
                Toggle("Shadow", isOn: $shadow)
                    .frame(width: 80)
            }
        }
        .padding(8)
    }
} 