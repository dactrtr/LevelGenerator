import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ControlGrid: View {
  @Binding var x: Double  // 0.0 to 1.0
  @Binding var y: Double  // 0.0 to 1.0
  let width: CGFloat
  let height: CGFloat
  
  private let gridSize = 15
  #if os(iOS)
  private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
  #endif
  @State private var touchLocation: CGPoint = .zero
  @State private var previousGridPosition: (Int, Int) = (-1, -1)
  
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let height = geometry.size.height
      let circleSpacingX = width / CGFloat(gridSize)
      let circleSpacingY = height / CGFloat(gridSize)
      let baseRadius = min(circleSpacingX, circleSpacingY) * 0.25
      
      ZStack {
        // Background
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.1))
          .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
        
        // Grid of circles
        ForEach(0..<gridSize, id: \.self) { row in
          ForEach(0..<gridSize, id: \.self) { col in
            let position = CGPoint(
              x: circleSpacingX * (CGFloat(col) + 0.5),
              y: circleSpacingY * (CGFloat(row) + 0.5)
            )
            
            let distance = distance(from: position, to: touchLocation)
            let scale = calculateScale(distance: distance, maxDistance: min(circleSpacingX, circleSpacingY) * 2)
            let color = calculateColor(distance: distance, maxDistance: min(circleSpacingX, circleSpacingY) * 2)
            
            Circle()
              .fill(color)
              .frame(width: baseRadius * 2, height: baseRadius * 2)
              .scaleEffect(scale)
              .position(position)
          }
        }
        
        // Value indicators
        let xPosition = width * x
        let yPosition = height * y
        
        // X-axis indicator
        Rectangle()
          .fill(Color.blue.opacity(0.3))
          .frame(width: 2, height: height)
          .position(x: xPosition, y: height/2)
        
        // Y-axis indicator
        Rectangle()
          .fill(Color.green.opacity(0.3))
          .frame(width: width, height: 2)
          .position(x: width/2, y: yPosition)
      }
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            touchLocation = value.location
            updateValues(location: value.location, in: geometry.size)
          }
          .onEnded { _ in
            touchLocation = .zero
            previousGridPosition = (-1, -1)
          }
      )
    }
  }
  
  private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
    guard point2 != .zero else { return .infinity }
    let deltaX = point1.x - point2.x
    let deltaY = point1.y - point2.y
    return sqrt(deltaX * deltaX + deltaY * deltaY)
  }
  
  private func calculateScale(distance: CGFloat, maxDistance: CGFloat) -> CGFloat {
    guard touchLocation != .zero else { return 1.0 }
    if distance > maxDistance { return 1.0 }
    return 1.0 + (1.0 - distance/maxDistance) * 0.5
  }
  
  private func calculateColor(distance: CGFloat, maxDistance: CGFloat) -> Color {
    guard touchLocation != .zero else { return Color.gray.opacity(0.3) }
    if distance > maxDistance { return Color.gray.opacity(0.3) }
    
    let progress = distance/maxDistance
    let opacity = 0.3 + (1.0 - progress) * 0.4
    return Color.gray.opacity(opacity)
  }
  
  private func updateValues(location: CGPoint, in size: CGSize) {
    // Calculamos la proporción de la posición en el control grid (0-1)
    let proportionX = location.x / size.width
    let proportionY = location.y / size.height
    
    // Mapeamos esa proporción al rango del mapa
    let mapX = 16.0 + (384.0 - 16.0) * proportionX  // Rango 16-384
    let mapY = 16.0 + (224.0 - 16.0) * proportionY  // Rango 16-224
    
    // Aseguramos que los valores estén dentro de los límites
    x = max(16, min(384, mapX))
    y = max(16, min(224, mapY))
    
    let currentGridX = Int(proportionX * CGFloat(gridSize))
    let currentGridY = Int(proportionY * CGFloat(gridSize))
    
    if currentGridX != previousGridPosition.0 || currentGridY != previousGridPosition.1 {
        #if os(iOS)
        hapticFeedback.impactOccurred()
        #endif
        previousGridPosition = (currentGridX, currentGridY)
    }
  }
}

// Example usage view
struct controlGridView: View {
  @State private var xValue: Double = 0.5
  @State private var yValue: Double = 0.5
  
  var body: some View {
    VStack {
      ControlGrid(x: $xValue, y: $yValue, width: 300, height: 300)
      
      Text("X: \(xValue, specifier: "%.2f")")
      Text("Y: \(yValue, specifier: "%.2f")")
    }
  }
}

struct controlGridView_Previews: PreviewProvider {
  static var previews: some View {
    VStack{
    
      controlGridView()
    }
  }
}
