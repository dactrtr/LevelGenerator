import SwiftUI

struct RoomInfoView: View {
    @Binding var level: Int
    @Binding var floorNumber: Int
    @Binding var tile: Int
    @Binding var light: Double
    @Binding var shadow: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Room Information")
                .font(.headline)
            
            GroupBox {
                VStack(spacing: 16) {
                    // Level, Floor and Tile controls in one row
                    HStack(spacing: 24) {
                        // Level control
                        VStack(alignment: .leading) {
                            Text("Level")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Stepper(value: $level, in: 1...100) {
                                Text("\(level)")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .leading)
                            }
                        }
                        
                        // Floor control
                        VStack(alignment: .leading) {
                            Text("Floor")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Stepper(value: $floorNumber, in: 1...10) {
                                Text("\(floorNumber)")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .leading)
                            }
                        }
                        
                        // Tile control
                        VStack(alignment: .leading) {
                            Text("Tile")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Stepper(value: $tile, in: 1...20) {
                                Text("\(tile)")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .leading)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Light control
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Light: \(light, specifier: "%.1f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Slider(value: $light)
                            .accentColor(.blue)
                    }
                    
                    Divider()
                    
                    // Shadow toggle
                    Toggle("Enable Shadow", isOn: $shadow)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
        }
        .padding(12)
    }
} 