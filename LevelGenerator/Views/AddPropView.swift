import SwiftUI

struct AddPropView: View {
    @Binding var selectedProp: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    @State private var nocollide: Bool = false
    
    let props = ["chair","fellchair","deadrat", "table","fellTable", "box", "trash", "blood", "blood2", "toxic", "xtree-1", "xtree-2", "xtree-3", "xtree-4","microwave","gifts","gift", "smallTable"]
    let columns = Array(repeating: GridItem(.fixed(48), spacing: 8), count: 8)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.fixed(48))], spacing: 8) {
                    ForEach(props, id: \.self) { prop in
                        Button {
                            selectedProp = prop
                        } label: {
                            Image(prop)
                                .resizable()
                                .frame(width: 32, height: 32)
                                .padding(8)
                                .background(selectedProp == prop ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .frame(height: 64)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
            .scrollTargetBehavior(.paging)
            
            Toggle(isOn: $nocollide) {
                Text("No Collide")
                    .font(.footnote)
            }
            
            Button {
                placedItems.append(
                    PlacedItem(
                        type: selectedProp,
                        x: currentX,
                        y: currentY,
                        itemType: .prop,
                        nocollide: nocollide
                    )
                )
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.small)
            
            ControlGrid(x: $currentX, y: $currentY, width: 400, height: 240)
                .frame(height: 120)
                .cornerRadius(8)
        }
        .padding(12)
    }
} 