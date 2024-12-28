import SwiftUI

struct RoomInfoView: View {
    @Binding var level: Int
    @Binding var floorNumber: Int
    @Binding var tile: Int
    @Binding var light: Double
    @Binding var shadow: Bool
    @Binding var doorTop: Bool
    @Binding var doorRight: Bool
    @Binding var doorDown: Bool
    @Binding var doorLeft: Bool
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(spacing: 16) {
                        // Room Info
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                // Level, Floor, Tile y Shadow en una línea
                                HStack(spacing: 16) {
                                    // Level
                                    HStack(spacing: 4) {
                                        Text("Level")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Stepper(value: $level, in: 1...100) {
                                            Text("\(level)")
                                                .monospacedDigit()
                                                .frame(width: 30, alignment: .leading)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                    
                                    // Floor
                                    HStack(spacing: 4) {
                                        Text("Floor")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Stepper(value: $floorNumber, in: 1...10) {
                                            Text("\(floorNumber)")
                                                .monospacedDigit()
                                                .frame(width: 30, alignment: .leading)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                    
                                    // Tile
                                    HStack(spacing: 4) {
                                        Text("Tile")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Stepper(value: $tile, in: 1...20) {
                                            Text("\(tile)")
                                                .monospacedDigit()
                                                .frame(width: 30, alignment: .leading)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                    
                                    // Shadow toggle
                                    Toggle("Enable Shadow", isOn: $shadow)
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
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
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Doors
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Doors")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 16) {
                                    Toggle("Top", isOn: $doorTop)
                                    Toggle("Right", isOn: $doorRight)
                                }
                                
                                HStack(spacing: 16) {
                                    Toggle("Down", isOn: $doorDown)
                                    Toggle("Left", isOn: $doorLeft)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text("Room Information")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            )
        }
        .padding(16)
    }
} 