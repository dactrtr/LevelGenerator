#if os(macOS)
import SwiftUI

struct MacContentView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var importText: String
    @Binding var showingImportAlert: Bool
    @Binding var importAlertMessage: String
    
    @State private var selectedLevelId: UUID?
    @State private var selectedScriptId: UUID?
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var showingDeleteScriptAlert = false
    @State private var scriptIdToDelete: UUID?
    @State private var showingLDtkFilePicker = false
    @State private var showingLDtkErrorAlert = false
    @State private var ldtkErrorMessage = ""
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar con secciones principales
            List(selection: $selectedSection) {
                NavigationLink(value: ContentSection.levels) {
                    Label("Levels", systemImage: "square.stack.3d.up")
                }
                
                NavigationLink(value: ContentSection.scripts) {
                    Label("Scripts", systemImage: "text.word.spacing")
                }
            }
            .navigationTitle("Content")
            .listStyle(.sidebar)
        } content: {
            // Lista de contenido con selección
            VStack(spacing: 0) {
                List(selection: selectedSection == .levels ? $selectedLevelId : $selectedScriptId) {
                    if selectedSection == .levels {
                        Section {
                            ForEach(contentStore.levels) { level in
                                NavigationLink(value: level.id) {
                                    LevelRow(level: level)
                                }
                            }
                            .onDelete { indexSet in
                                contentStore.deleteLevel(at: indexSet)
                                selectedLevelId = nil
                            }
                        }
                    } else {
                        ForEach(contentStore.scripts) { script in
                            NavigationLink(value: script.id) {
                                ScriptRow(script: script)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    scriptIdToDelete = script.id
                                    showingDeleteScriptAlert = true
                                } label: {
                                    Label("Delete Script", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            contentStore.deleteScript(at: indexSet)
                            selectedScriptId = nil
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                if selectedSection == .scripts, let name = contentStore.ldtkFileName {
                    Text("\(name) · \(contentStore.ldtkScriptNames.count) scripts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        if selectedSection == .levels {
                            showingNewLevelSheet = true
                        } else {
                            showingNewScriptSheet = true
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }

                    if selectedSection == .scripts, selectedScriptId != nil {
                        Button(role: .destructive) {
                            scriptIdToDelete = selectedScriptId
                            showingDeleteScriptAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if selectedSection == .scripts {
                        Button {
                            showingLDtkFilePicker = true
                        } label: {
                            Label("Cargar LDtk…", systemImage: "doc.badge.arrow.up")
                        }
                    }

                    Menu {
                        Button {
                            showingExportSheet = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            showingImportSheet = true
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        } detail: {
            // Vista de detalle
            Group {
                if selectedSection == .levels {
                    if let selectedId = selectedLevelId,
                       let index = contentStore.levels.firstIndex(where: { $0.id == selectedId }) {
                        LevelEditorView(level: contentStore.levelBinding(at: index))
                            .id(selectedId) // Para forzar la actualización de la vista
                    } else {
                        ContentUnavailableView {
                            Label("No Level Selected", systemImage: "square.stack.3d.up")
                        } description: {
                            Text("Select a level from the list to edit it")
                        }
                    }
                } else {
                    if let selectedId = selectedScriptId,
                       let index = contentStore.scripts.firstIndex(where: { $0.id == selectedId }) {
                        ScriptView(
                            script: contentStore.scriptBinding(at: index),
                            availableScriptNames: contentStore.ldtkScriptNames
                        )
                        .id(selectedId)
                    } else {
                        ContentUnavailableView {
                            Label("No Script Selected", systemImage: "text.word.spacing")
                        } description: {
                            Text("Select a script from the list to edit it")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewLevelSheet) {
            NewLevelSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NewScriptSheet(contentStore: contentStore)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(contentStore: contentStore, isPresented: $showingExportSheet)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(
                contentStore: contentStore,
                isPresented: $showingImportSheet,
                importText: $importText,
                showingAlert: $showingImportAlert,
                alertMessage: $importAlertMessage
            )
        }
        .alert("Delete Script", isPresented: $showingDeleteScriptAlert) {
            Button("Delete", role: .destructive) {
                if let id = scriptIdToDelete,
                   let index = contentStore.scripts.firstIndex(where: { $0.id == id }) {
                    contentStore.deleteScript(at: IndexSet([index]))
                    if selectedScriptId == id {
                        selectedScriptId = nil
                    }
                }
                scriptIdToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                scriptIdToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this script? This action cannot be undone.")
        }
        .fileImporter(
            isPresented: $showingLDtkFilePicker,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    try contentStore.loadLDtkNames(from: url)
                } catch {
                    ldtkErrorMessage = error.localizedDescription
                    showingLDtkErrorAlert = true
                }
            case .failure(let error):
                ldtkErrorMessage = error.localizedDescription
                showingLDtkErrorAlert = true
            }
        }
        .alert("Error al cargar LDtk", isPresented: $showingLDtkErrorAlert) {
            Button("OK") {}
        } message: {
            Text(ldtkErrorMessage)
        }
    }
}
#endif 
