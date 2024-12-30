import SwiftUI

struct RoomNode: Identifiable {
    let id: UUID = UUID()
    let level: Int
    let room: Int
    let name: String
    var position: CGPoint
    var connections: Set<Int>
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
        .shadow(radius: 2)
        .position(node.position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    onDragChanged(value.location)
                }
        )
        .onTapGesture(perform: onTap)
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
    
    var body: some View {
        ForEach(nodes) { node in
            RoomNodeView(
                node: node,
                size: nodeSize,
                onTap: { onNodeTap(node) },
                onDragChanged: { newPosition in
                    onNodeDragged(node, newPosition)
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
    
    private let nodeSize: CGFloat = 60
    private let spacing: CGFloat = 100
    
    init(levels: [SavedLevel], contentStore: ContentStore) {
        self.levels = levels
        self.contentStore = contentStore
        self._nodes = State(initialValue: Self.createInitialNodes(
            from: levels,
            savedPositions: contentStore.loadNodePositions()
        ))
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
                    },
                    onNodeDragged: updateNodePosition
                )
            }
            .frame(width: 1000, height: 1000)
        }
        .background(Color.black.opacity(0.05))
        .overlay(alignment: .topLeading) {
            nodeInfoOverlay
        }
        .onDisappear {
            // Guardar posiciones al cerrar la vista
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
        savedPositions: [ContentStore.NodePosition]
    ) -> [RoomNode] {
        var nodes: [RoomNode] = []
        var positions: [Int: CGPoint] = [:]
        let centerX: CGFloat = 500
        let centerY: CGFloat = 500
        
        // Cargar posiciones guardadas
        for position in savedPositions {
            positions[position.roomNumber] = CGPoint(x: position.x, y: position.y)
        }
        
        for level in levels {
            let connections = getConnections(for: level)
            let position = getPosition(
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
                connections: connections
            ))
        }
        
        return nodes
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