import SwiftUI

struct AddItemView: View {
    @Binding var selectedItem: String
    @Binding var currentX: Double
    @Binding var currentY: Double
    @Binding var placedItems: [PlacedItem]
    
    let availableItems = ["chair", "box", "fellchair", "table"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Control de muebles")
                .font(.headline)
                .padding(.top)
            
            Picker("Tipo", selection: $selectedItem) {
                ForEach(availableItems, id: \.self) { item in
                    Text(item.capitalized)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("X: \(Int(currentX))")
                    Slider(value: $currentX, in: 16...384)
                }
                
                VStack(alignment: .leading) {
                    Text("Y: \(Int(currentY))")
                    Slider(value: $currentY, in: 16...224)
                }
            }
            
            HStack {
                Image(selectedItem)
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Button(action: {
                    let newItem = PlacedItem(type: selectedItem, x: currentX, y: currentY, itemType: .furniture)
                    placedItems.append(newItem)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
} 