import SwiftUI

enum ContentSection {
    case levels, scripts
}

struct ContentListView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var selectedSection: ContentSection
    @Binding var showingNewLevelSheet: Bool
    @Binding var showingNewScriptSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var showingImportSheet: Bool
    
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
                    NavigationLink {
                        LevelEditorView(level: contentStore.levelBinding(at: index))
                    } label: {
                        VStack(alignment: .leading) {
                            Text(contentStore.levels[index].name)
                                .font(.headline)
                            Text("Level \(contentStore.levels[index].level) - Room \(contentStore.levels[index].roomNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    contentStore.deleteLevel(at: indexSet)
                }
            } else {
                ForEach(contentStore.scripts.indices, id: \.self) { index in
                    NavigationLink {
                        ScriptView(script: contentStore.scriptBinding(at: index))
                    } label: {
                        VStack(alignment: .leading) {
                            Text(contentStore.scripts[index].name)
                                .font(.headline)
                            Text("\(contentStore.scripts[index].dialogs.count) dialogs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    contentStore.deleteScript(at: indexSet)
                }
            }
        }
        .navigationTitle(selectedSection == .levels ? "Levels" : "Scripts")
        .toolbar {
            ToolbarItemGroup {
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
        }
    }
}

struct ImportView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var isPresented: Bool
    @Binding var importText: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $importText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                
                HStack {
                    Button("Import and Replace") {
                        if contentStore.importFromJSON(importText) {
                            isPresented = false
                            importText = ""
                        } else {
                            alertMessage = "Invalid data format"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Import and Merge") {
                        if contentStore.mergeFromJSON(importText) {
                            isPresented = false
                            importText = ""
                        } else {
                            alertMessage = "Invalid data format"
                            showingAlert = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Import Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        importText = ""
                    }
                }
            }
            .alert("Import Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

struct ContentManagerView: View {
    @StateObject private var contentStore = ContentStore()
    @State private var selectedSection: ContentSection = .levels
    @State private var showingNewLevelSheet = false
    @State private var showingNewScriptSheet = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingImportAlert = false
    @State private var importAlertMessage = ""
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            ContentListView(
                contentStore: contentStore,
                selectedSection: $selectedSection,
                showingNewLevelSheet: $showingNewLevelSheet,
                showingNewScriptSheet: $showingNewScriptSheet,
                showingExportSheet: $showingExportSheet,
                showingImportSheet: $showingImportSheet
            )
        }
        .sheet(isPresented: $showingNewLevelSheet) {
            NavigationStack {
                NewLevelSheet(contentStore: contentStore)
            }
        }
        .sheet(isPresented: $showingNewScriptSheet) {
            NavigationStack {
                NewScriptSheet(contentStore: contentStore)
            }
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
        #else
        MacContentView(
            contentStore: contentStore,
            selectedSection: $selectedSection,
            showingNewLevelSheet: $showingNewLevelSheet,
            showingNewScriptSheet: $showingNewScriptSheet,
            showingExportSheet: $showingExportSheet,
            showingImportSheet: $showingImportSheet,
            importText: $importText,
            showingImportAlert: $showingImportAlert,
            importAlertMessage: $importAlertMessage
        )
        #endif
    }
}

struct ExportView: View {
    @ObservedObject var contentStore: ContentStore
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let jsonString = contentStore.exportToJSON() {
                    Text(jsonString)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
            }
            .navigationTitle("Export Data")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
} 