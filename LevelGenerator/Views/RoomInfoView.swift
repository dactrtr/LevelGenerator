import SwiftUI

struct RoomInfoView: View {
    @Binding var level: Int
    @Binding var floorNumber: Int
    @Binding var tile: Int
    @Binding var light: Double
    @Binding var shadow: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room Information")
                .font(.title3)
                .fontWeight(.semibold)
            
            GroupBox {
                VStack(spacing: 16) {
                    // Level, Floor and Tile controls in one row
                    HStack(spacing: 16) {
                        // Level control
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Level")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Stepper(value: $level, in: 1...100) {
                                Text("\(level)")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .leading)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Floor control
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Floor")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Stepper(value: $floorNumber, in: 1...10) {
                                Text("\(floorNumber)")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .leading)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Tile control
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tile")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Stepper(value: $tile, in: 1...20) {
                                Text("\(tile)")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .leading)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Light control
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Light: \(light, specifier: "%.1f")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Slider(value: $light)
                            .tint(.blue)
                    }
                    
                    Divider()
                    
                    // Shadow toggle
                    Toggle(isOn: $shadow) {
                        Text("Enable Shadow")
                            .foregroundStyle(.primary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
    }
} 