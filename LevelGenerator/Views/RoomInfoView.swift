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
    @Binding var doorTopLeadsTo: Int
    @Binding var doorRightLeadsTo: Int
    @Binding var doorDownLeadsTo: Int
    @Binding var doorLeftLeadsTo: Int
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 16) {
            // Room Info
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // Level, Floor, Tile y Shadow en una línea
                    VStack(spacing: 16) {
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
                        
                        // Room
                        HStack(spacing: 4) {
                            Text("Room")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Stepper(value: $floorNumber, in: 1...100) {
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Doors")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.up.circle")
                        Toggle("⬆️", isOn: $doorTop)
                            .labelsHidden()
                        if doorTop {
                            Text("Room \(doorTopLeadsTo)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper(value: $doorTopLeadsTo, in: 1...20) {
                                Text("\(doorTopLeadsTo)")
                                    .monospacedDigit()
                            }
                            .labelsHidden()
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.right.circle")
                        Toggle("➡️", isOn: $doorRight)
                            .labelsHidden()
                        if doorRight {
                            Text("Room \(doorRightLeadsTo)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper(value: $doorRightLeadsTo, in: 1...20) {
                                Text("\(doorRightLeadsTo)")
                                    .monospacedDigit()
                            }
                            .labelsHidden()
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.down.circle")
                        Toggle("⬇️", isOn: $doorDown)
                            .labelsHidden()
                        if doorDown {
                            Text("Room \(doorDownLeadsTo)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper(value: $doorDownLeadsTo, in: 1...20) {
                                Text("\(doorDownLeadsTo)")
                                    .monospacedDigit()
                            }
                            .labelsHidden()
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.left.circle")
                        Toggle("⬅️", isOn: $doorLeft)
                            .labelsHidden()
                        if doorLeft {
                            Text("Room \(doorLeftLeadsTo)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper(value: $doorLeftLeadsTo, in: 1...20) {
                                Text("\(doorLeftLeadsTo)")
                                    .monospacedDigit()
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .padding(4)
    }
} 
