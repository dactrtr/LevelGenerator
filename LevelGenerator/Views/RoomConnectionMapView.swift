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
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(Color.gray, lineWidth: 2)
    }
}

struct RoomNodeView: View {
    let node: RoomNode
    let size: CGFloat
    let onTap: () -> Void
    
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
        .onTapGesture(perform: onTap)
    }
}

struct ConnectionsView: View {
    let nodes: [RoomNode]
    let nodeSize: CGFloat
    
    var body: some View {
        ForEach(nodes) { node in
            ForEach(Array(node.connections), id: \.self) { connectedRoom in
                if let targetNode = nodes.first(where: { $0.room == connectedRoom }) {
                    ConnectionLine(
                        from: centerPoint(for: node),
                        to: centerPoint(for: targetNode)
                    )
                }
            }
        }
    }
    
    private func centerPoint(for node: RoomNode) -> CGPoint {
        CGPoint(
            x: node.position.x + nodeSize/2,
            y: node.position.y + nodeSize/2
        )
    }
}

struct NodesView: View {
    let nodes: [RoomNode]
    let nodeSize: CGFloat
    let onNodeTap: (RoomNode) -> Void
    
    var body: some View {
        ForEach(nodes) { node in
            RoomNodeView(node: node, size: nodeSize) {
                onNodeTap(node)
            }
        }
    }
}

struct RoomConnectionMapView: View {
    let levels: [SavedLevel]
    @State private var nodes: [RoomNode] = []
    @State private var selectedNode: RoomNode?
    
    private let nodeSize: CGFloat = 60
    private let spacing: CGFloat = 100
    
    init(levels: [SavedLevel]) {
        self.levels = levels
        self._nodes = State(initialValue: Self.createInitialNodes(from: levels))
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                ConnectionsView(nodes: nodes, nodeSize: nodeSize)
                NodesView(nodes: nodes, nodeSize: nodeSize) { node in
                    selectedNode = node
                }
            }
            .frame(width: 1000, height: 1000)
        }
        .background(Color.black.opacity(0.05))
        .overlay(alignment: .topLeading) {
            nodeInfoOverlay
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
    
    private static func createInitialNodes(from levels: [SavedLevel]) -> [RoomNode] {
        var nodes: [RoomNode] = []
        var positions: [Int: CGPoint] = [:]
        let centerX: CGFloat = 500
        let centerY: CGFloat = 500
        
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