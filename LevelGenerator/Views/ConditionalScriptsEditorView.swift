import SwiftUI

// Modo del panel central en ScriptView
enum CenterMode {
    case dialogs
    case conditions
}

// MARK: - Fila de una condición individual

struct ConditionalScriptRowView: View {
    @Binding var condition: ConditionalScript
    var onDelete: () -> Void
    let availableScriptNames: [String]

    private let operators = [">", "<", ">=", "<=", "==", "!="]

    var body: some View {
        HStack(spacing: 10) {

            // ── Variable picker ──────────────────────────────────────────
            Picker("Variable", selection: $condition.variablePath) {
                ForEach(PlayerVariable.all) { variable in
                    Text(variable.label).tag(variable.path)
                }
            }
            .frame(width: 160)
            .onChange(of: condition.variablePath) { _, newPath in
                if let variable = PlayerVariable.all.first(where: { $0.path == newPath }) {
                    // Actualizar tipo y resetear campos del tipo anterior
                    condition.variableType = variable.type
                    if variable.type == "number" {
                        condition.negate = false
                    } else {
                        condition.numericOperator = ">"
                        condition.numericValue = 0
                    }
                }
            }

            // ── Bool: toggle Negar ───────────────────────────────────────
            if condition.variableType == "bool" {
                Toggle(isOn: $condition.negate) {
                    Text("Negar")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .tint(.orange)
                .frame(width: 70)
            }

            // ── Number: operador + valor ─────────────────────────────────
            if condition.variableType == "number" {
                Picker("Op", selection: $condition.numericOperator) {
                    ForEach(operators, id: \.self) { op in
                        Text(op).tag(op)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                TextField("Valor", value: $condition.numericValue, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
            }

            Spacer()

            // ── Script destino ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 2) {
                TextField("Script", text: $condition.scriptName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 145)

                // Warning si el script no existe en el catálogo
                if !condition.scriptName.isEmpty,
                   !availableScriptNames.isEmpty,
                   !availableScriptNames.contains(condition.scriptName) {
                    Text("⚠️ Script no existe")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }

            // ── Terminal (!) toggle ──────────────────────────────────────
            Toggle(isOn: $condition.isTerminal) {
                Text("!")
                    .font(.system(.body, design: .monospaced).bold())
            }
            .toggleStyle(.button)
            .tint(.red)
            .help("Terminal: el trigger se destruye al ejecutarse")
            .frame(width: 44)

            // ── Preview del string generado ──────────────────────────────
            Text(condition.scriptName.isEmpty ? "…" : condition.conditionString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(minWidth: 80, maxWidth: 220, alignment: .leading)

            // ── Botón eliminar ───────────────────────────────────────────
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 2)
    }
}

// MARK: - Editor de lista de condiciones

struct ConditionalScriptsEditorView: View {
    @Binding var conditions: [ConditionalScript]
    let availableScriptNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ───────────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("conditionalScripts")
                        .font(.system(.subheadline, design: .monospaced).bold())
                    Text("El juego evalúa en orden y ejecuta el primero que matchea. Arrastrá para reordenar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    let first = PlayerVariable.all[0]
                    conditions.append(ConditionalScript(
                        variablePath: first.path,
                        variableType: first.type
                    ))
                } label: {
                    Label("Agregar condición", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            if conditions.isEmpty {
                // ── Estado vacío ─────────────────────────────────────────
                ContentUnavailableView(
                    "Sin condiciones",
                    systemImage: "text.badge.plus",
                    description: Text("Agregá condiciones para ejecutar distintos scripts según el estado del jugador.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // ── Cabeceras de columnas ─────────────────────────────────
                HStack(spacing: 10) {
                    // espacio para drag handle del List
                    Spacer().frame(width: 30)
                    Text("Variable")
                        .frame(width: 160, alignment: .leading)
                    Text("Condición")
                        .frame(minWidth: 80, alignment: .leading)
                    Spacer()
                    Text("Script destino")
                        .frame(width: 145, alignment: .leading)
                    Text("!")
                        .frame(width: 44, alignment: .center)
                        .help("Terminal")
                    Text("Preview")
                        .frame(minWidth: 80, alignment: .leading)
                    Spacer().frame(width: 24)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(PlatformColor.secondaryBackground)

                Divider()

                // ── Lista reordenable ─────────────────────────────────────
                List {
                    ForEach($conditions) { $condition in
                        ConditionalScriptRowView(
                            condition: $condition,
                            onDelete: {
                                conditions.removeAll { $0.id == condition.id }
                            },
                            availableScriptNames: availableScriptNames
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                    }
                    .onMove { from, to in
                        conditions.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                #if os(iOS)
                .environment(\.editMode, .constant(.active))
                #endif
            }
        }
    }
}
