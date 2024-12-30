import SwiftUI

struct AddTriggerView: View {
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    @Binding var previewWidth: Double
    @Binding var previewHeight: Double
    @State private var scriptName: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Size Controls
            GroupBox {
                HStack(spacing: 12) {
                    // Width Control
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width: \(Int(previewWidth))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $previewWidth, in: 20...200)
                            .tint(.purple)
                    }
                    
                    // Height Control
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height: \(Int(previewHeight))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Slider(value: $previewHeight, in: 20...200)
                            .tint(.purple)
                    }
                }
            }
            
            // Script Name Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Script Name")
                    .font(.footnote)
                TextField("Enter script name", text: $scriptName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Add Button
            Button {
                placedItems.append(
                    PlacedItem(
                        type: "trigger",
                        x: currentX,
                        y: currentY,
                        itemType: .trigger,
                        width: previewWidth,
                        height: previewHeight,
                        script: scriptName.isEmpty ? nil : scriptName
                    )
                )
                scriptName = ""
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.small)
            .disabled(scriptName.isEmpty)
            
            // Position Control Grid
            ControlGrid(x: $currentX, y: $currentY, width: 400, height: 240)
                .frame(height: 120)
                .cornerRadius(8)
        }
        .padding(12)
    }
} 
