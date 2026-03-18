import SwiftUI

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    @Binding var selectedLevel: SavedLevel?
    @Binding var selectedScript: SavedScript?
    @State private var showingConnectionMap = false
    @State private var showingLDtkFilePicker = false
    @State private var showingLDtkErrorAlert = false
    @State private var ldtkErrorMessage = ""
    
    var body: some View {
        List {
            Picker("Section", selection: $selectedSection) {
                Text("Levels").tag(ContentSection.levels)
                Text("Scripts").tag(ContentSection.scripts)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedSection == .levels {
                ForEach(contentStore.levels.indices, id: \.self) { index in
                    #if os(iOS)
                    NavigationLink {
                        LevelEditorView(level: contentStore.levelBinding(at: index))
                    } label: {
                        LevelRow(level: contentStore.levels[index])
                    }
                    #else
                    LevelRow(level: contentStore.levels[index])
                        .onTapGesture {
                            selectedLevel = contentStore.levels[index]
                        }
                        .background(
                            selectedLevel?.id == contentStore.levels[index].id ?
                                Color.blue.opacity(0.1) : Color.clear
                        )
                    #endif
                }
                .onDelete { indexSet in
                    contentStore.deleteLevel(at: indexSet)
                }
            } else {
                ForEach(contentStore.scripts.indices, id: \.self) { index in
                    #if os(iOS)
                    NavigationLink {
                        ScriptView(
                            script: contentStore.scriptBinding(at: index),
                            availableScriptNames: contentStore.ldtkScriptNames
                        )
                    } label: {
                        ScriptRow(script: contentStore.scripts[index])
                    }
                    #else
                    ScriptRow(script: contentStore.scripts[index])
                        .onTapGesture {
                            selectedScript = contentStore.scripts[index]
                        }
                        .background(
                            selectedScript?.id == contentStore.scripts[index].id ?
                                Color.blue.opacity(0.1) : Color.clear
                        )
                    #endif
                }
                .onDelete { indexSet in
                    contentStore.deleteScript(at: indexSet)
                }
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if selectedSection == .levels {
                        showingNewLevelSheet = true
                    } else {
                        showingNewScriptSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .primaryAction) {
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
                    Image(systemName: "ellipsis.circle")
                }
            }

            if selectedSection == .scripts {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLDtkFilePicker = true
                    } label: {
                        Image(systemName: "doc.badge.arrow.up")
                    }
                }
            }
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
        #endif
    }
} 