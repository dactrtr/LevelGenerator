import SwiftUI

struct AddTriggerView: View {
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var width: Double = 60
    @State private var height: Double = 30
    @State private var script: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Triggers")
                .font(.headline)
                .padding(.top, 8)
            
            GroupBox {
                VStack(spacing: 12) {
                    // Position X & Y
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position X")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $currentX, in: 16...384)
                            .tint(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Position Y")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $currentY, in: 16...224)
                            .tint(.purple)
                    }
                    
                    // Width & Height
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width: \(Int(width))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $width, in: 30...200)
                            .tint(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height: \(Int(height))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $height, in: 30...200)
                            .tint(.purple)
                    }
                    
                    // Script number
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Script")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Stepper(value: $script, in: 1...100) {
                            Text("\(script)")
                                .monospacedDigit()
                                .frame(width: 30, alignment: .leading)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            
            Button {
                placedItems.append(
                    PlacedItem(
                        type: "trigger",
                        x: currentX,
                        y: currentY,
                        itemType: .trigger,
                        width: width,
                        height: height,
                        script: script
                    )
                )
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.small)
        }
        .padding(12)
    }
} 