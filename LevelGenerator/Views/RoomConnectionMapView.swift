import SwiftUI

struct RoomNode: Identifiable {
    let id: UUID = UUID()
    let level: Int
    let room: Int
    let name: String
    var position: CGPoint
    var connections: Set<Int>
    var borderColor: Color = .clear  // Color por defecto
}

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let direction: DoorDirection
    let nodeSize: CGFloat
    
    enum DoorDirection {
        case top, right, down, left
    }
    
    var body: some View {
        Path { path in
            let (start, control1, control2, end) = getConnectionPoints()
            
            path.move(to: start)
            path.addCurve(
                to: end,
                control1: control1,
                control2: control2
            )
        }
        .stroke(Color.gray, lineWidth: 2)
    }
    
    private func getConnectionPoints() -> (start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) {
        let halfNode = nodeSize/2
        
        // Puntos de inicio según la dirección de la puerta
        let start: CGPoint
        let control1: CGPoint
        switch direction {
        case .top:
            start = CGPoint(x: from.x, y: from.y - halfNode)
            control1 = CGPoint(x: from.x, y: from.y - 50)
        case .right:
            start = CGPoint(x: from.x + halfNode, y: from.y)
            control1 = CGPoint(x: from.x + 50, y: from.y)
        case .down:
            start = CGPoint(x: from.x, y: from.y + halfNode)
            control1 = CGPoint(x: from.x, y: from.y + 50)
        case .left:
            start = CGPoint(x: from.x - halfNode, y: from.y)
            control1 = CGPoint(x: from.x - 50, y: from.y)
        }
        
        // Puntos finales según la dirección opuesta
        let end: CGPoint
        let control2: CGPoint
        let oppositeDirection = getOppositeDirection()
        switch oppositeDirection {
        case .top:
            end = CGPoint(x: to.x, y: to.y - halfNode)
            control2 = CGPoint(x: to.x, y: to.y - 50)
        case .right:
            end = CGPoint(x: to.x + halfNode, y: to.y)
            control2 = CGPoint(x: to.x + 50, y: to.y)
        case .down:
            end = CGPoint(x: to.x, y: to.y + halfNode)
            control2 = CGPoint(x: to.x, y: to.y + 50)
        case .left:
            end = CGPoint(x: to.x - halfNode, y: to.y)
            control2 = CGPoint(x: to.x - 50, y: to.y)
        }
        
        return (start, control1, control2, end)
    }
    
    private func getOppositeDirection() -> DoorDirection {
        switch direction {
        case .top: return .down
        case .right: return .left
        case .down: return .top
        case .left: return .right
        }
    }
}

struct RoomNodeView: View {
    let node: RoomNode
    let size: CGFloat
    let onTap: () -> Void
    let onDragChanged: (CGPoint) -> Void
    let onColorChanged: (Color) -> Void
    
    var body: some View {
        VStack {
            Text("Room \(node.room)")
                .font(.caption)
                .bold()
            Text(node.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: size, height: size)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(node.borderColor, lineWidth: 3)
        )
        .position(node.position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    onDragChanged(value.location)
                }
        )
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button {
                onColorChanged(.red)
            } label: {
                Label("Power item", systemImage: "figure.run")
                    .foregroundColor(.red)
            }
            
            Button {
                onColorChanged(.blue)
            } label: {
                Label("Puzzle", systemImage: "puzzlepiece.extension.fill")
                    .foregroundColor(.blue)
            }
            
            Button {
                onColorChanged(.green)
            } label: {
                Label("Story", systemImage: "popcorn.fill")
                    .foregroundColor(.green)
            }
            
            Button {
                onColorChanged(.clear)
            } label: {
                Label("No Border", systemImage: "circle.slash")
            }
        }
    }
}

struct ConnectionsView: View {
    let nodes: [RoomNode]
    let nodeSize: CGFloat
    let levels: [SavedLevel]
    
    var body: some View {
        ForEach(nodes) { node in
            if let level = levels.first(where: { $0.roomNumber == node.room }) {
                // Conexión puerta superior
                if level.doors.top,
                   let targetNode = nodes.first(where: { $0.room == level.doors.topLeadsTo }) {
                    ConnectionLine(
                        from: node.position,
                        to: targetNode.position,
                        direction: .top,
                        nodeSize: nodeSize
                    )
                }
                
                // Conexión puerta derecha
                if level.doors.right,
                   let targetNode = nodes.first(where: { $0.room == level.doors.rightLeadsTo }) {
                    ConnectionLine(
                        from: node.position,
                        to: targetNode.position,
                        direction: .right,
                        nodeSize: nodeSize
                    )
                }
                
                // Conexión puerta inferior
                if level.doors.down,
                   let targetNode = nodes.first(where: { $0.room == level.doors.downLeadsTo }) {
                    ConnectionLine(
                        from: node.position,
                        to: targetNode.position,
                        direction: .down,
                        nodeSize: nodeSize
                    )
                }
                
                // Conexión puerta izquierda
                if level.doors.left,
                   let targetNode = nodes.first(where: { $0.room == level.doors.leftLeadsTo }) {
                    ConnectionLine(
                        from: node.position,
                        to: targetNode.position,
                        direction: .left,
                        nodeSize: nodeSize
                    )
                }
            }
        }
    }
}

struct NodesView: View {
    let nodes: [RoomNode]
    let nodeSize: CGFloat
    let onNodeTap: (RoomNode) -> Void
    let onNodeDragged: (RoomNode, CGPoint) -> Void
    let onNodeColorChanged: (RoomNode, Color) -> Void
    
    var body: some View {
        ForEach(nodes) { node in
            RoomNodeView(
                node: node,
                size: nodeSize,
                onTap: { onNodeTap(node) },
                onDragChanged: { newPosition in
                    onNodeDragged(node, newPosition)
                },
                onColorChanged: { color in
                    onNodeColorChanged(node, color)
                }
            )
        }
    }
}

struct RoomConnectionMapView: View {
    let levels: [SavedLevel]
    @ObservedObject var contentStore: ContentStore
    @State private var nodes: [RoomNode] = []
    @State private var selectedNode: RoomNode?
    @State private var draggedNode: RoomNode?
    @State private var showingPreview = false
    
    private let nodeSize: CGFloat = 60
    private let spacing: CGFloat = 100
    
    var selectedLevel: SavedLevel? {
        guard let selectedNode = selectedNode else { return nil }
        return levels.first { $0.roomNumber == selectedNode.room }
    }
    
    init(levels: [SavedLevel], contentStore: ContentStore) {
        self.levels = levels
        self.contentStore = contentStore
        
        // Crear nodos con posiciones y estilos guardados
        let savedPositions = contentStore.loadNodePositions()
        let savedStyles = contentStore.loadNodeStyles()
        
        let initialNodes = Self.createInitialNodes(
            from: levels,
            savedPositions: savedPositions,
            savedStyles: savedStyles
        )
        self._nodes = State(initialValue: initialNodes)
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                ConnectionsView(nodes: nodes, nodeSize: nodeSize, levels: levels)
                NodesView(
                    nodes: nodes,
                    nodeSize: nodeSize,
                    onNodeTap: { node in
                        selectedNode = node
                        showingPreview = true
                    },
                    onNodeDragged: updateNodePosition,
                    onNodeColorChanged: updateNodeColor
                )
            }
            .frame(width: 1000, height: 1000)
        }
        .background(Color.black.opacity(0.05))
        .overlay(alignment: .topLeading) {
            nodeInfoOverlay
        }
        .sheet(isPresented: $showingPreview) {
            if let level = selectedLevel {
                NavigationStack {
                    VStack {
                        NodePreviewMapView(
                            placedItems: level.placedItems,
                            doorTop: level.doors.top,
                            doorRight: level.doors.right,
                            doorDown: level.doors.down,
                            doorLeft: level.doors.left,
                            doorTopLeadsTo: level.doors.topLeadsTo,
                            doorRightLeadsTo: level.doors.rightLeadsTo,
                            doorDownLeadsTo: level.doors.downLeadsTo,
                            doorLeftLeadsTo: level.doors.leftLeadsTo,
                            level: level.level
                        )
                        .frame(width: 600, height: 360)  // Tamaño aumentado
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room \(level.roomNumber)")
                                .font(.title)
                            Text(level.name)
                                .font(.title3)
                            Text("Level \(level.level)")
                                .font(.headline)
                            if let node = selectedNode {
                                Text("Connections: \(connectionsList(for: node))")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                    }
                    .frame(minWidth: 700, minHeight: 500)  // Tamaño mínimo del sheet
                    .navigationTitle("Room Preview")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingPreview = false
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            let positions = nodes.map { node in
                ContentStore.NodePosition(
                    roomNumber: node.room,
                    x: node.position.x,
                    y: node.position.y
                )
            }
            contentStore.saveNodePositions(positions)
        }
    }
    
    private func updateNodePosition(_ node: RoomNode, _ newPosition: CGPoint) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index].position = newPosition
        }
    }
    
    private func updateNodeColor(_ node: RoomNode, _ color: Color) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            var updatedNode = nodes[index]
            updatedNode.borderColor = color
            nodes[index] = updatedNode
            
            // Guardar los estilos actualizados
            contentStore.saveNodeStyles(nodes)
        }
    }
    
    private var nodeInfoOverlay: some View {
        Group {
            if let node = selectedNode {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Room \(node.room)")
                        .font(.headline)
                    Text(node.name)
                        .font(.subheadline)
                    Text("Level \(node.level)")
                        .font(.caption)
                    Text("Connections: \(connectionsList(for: node))")
                        .font(.caption)
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(10)
                .padding()
            }
        }
    }
    
    private func connectionsList(for node: RoomNode) -> String {
        Array(node.connections)
            .sorted()
            .map(String.init)
            .joined(separator: ", ")
    }
    
    private static func createInitialNodes(
        from levels: [SavedLevel],
        savedPositions: [ContentStore.NodePosition],
        savedStyles: [ContentStore.NodeStyle]
    ) -> [RoomNode] {
        var nodes: [RoomNode] = []
        var positions: [Int: CGPoint] = [:]
        let centerX: CGFloat = 500
        let centerY: CGFloat = 500
        
        // Cargar posiciones guardadas
        for position in savedPositions {
            positions[position.roomNumber] = CGPoint(x: position.x, y: position.y)
        }
        
        // Crear diccionario de colores guardados
        let styles = Dictionary(uniqueKeysWithValues: savedStyles.map { ($0.roomNumber, stringToColor($0.borderColor)) })
        
        for level in levels {
            let position = positions[level.roomNumber] ?? getPosition(
                for: level.roomNumber,
                in: &positions,
                nodeCount: nodes.count,
                totalNodes: levels.count,
                centerX: centerX,
                centerY: centerY
            )
            
            nodes.append(RoomNode(
                level: level.level,
                room: level.roomNumber,
                name: level.name,
                position: position,
                connections: getConnections(for: level),
                borderColor: styles[level.roomNumber] ?? .clear
            ))
        }
        
        return nodes
    }
    
    private static func stringToColor(_ string: String) -> Color {
        switch string {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        default: return .clear
        }
    }
    
    private static func getConnections(for level: SavedLevel) -> Set<Int> {
        Set([
            level.doors.topLeadsTo,
            level.doors.rightLeadsTo,
            level.doors.downLeadsTo,
            level.doors.leftLeadsTo
        ].filter { door in
            (level.doors.top && door == level.doors.topLeadsTo) ||
            (level.doors.right && door == level.doors.rightLeadsTo) ||
            (level.doors.down && door == level.doors.downLeadsTo) ||
            (level.doors.left && door == level.doors.leftLeadsTo)
        })
    }
    
    private static func getPosition(
        for roomNumber: Int,
        in positions: inout [Int: CGPoint],
        nodeCount: Int,
        totalNodes: Int,
        centerX: CGFloat,
        centerY: CGFloat
    ) -> CGPoint {
        if let existingPosition = positions[roomNumber] {
            return existingPosition
        }
        
        let angle = (2 * .pi * Double(nodeCount)) / Double(max(totalNodes, 1))
        let position = CGPoint(
            x: centerX + 200 * cos(angle),
            y: centerY + 200 * sin(angle)
        )
        positions[roomNumber] = position
        return position
    }
} 
