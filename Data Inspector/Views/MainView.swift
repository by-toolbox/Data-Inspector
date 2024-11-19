//
//  MainView.swift
//  Data Inspector
//
//  Created by Axel Martinez on 13/11/24.
//

import UniformTypeIdentifiers
import SwiftUI

struct MainView: View {
    let contentTypes: [UTType] = [.init(filenameExtension: "db")!]
    
    @State var isSidebarOpen: NavigationSplitViewVisibility = .automatic
    @State var isInspectorOpen: Bool = false
    @State var isFileDialogOpen: Bool = false
    @State var filePath: String?
    @State var selectedEntity: Entity?
    
    @StateObject var manager: SQLManager = .init()
    
    var body: some View {
        NavigationSplitView(columnVisibility: $isSidebarOpen) {
            SidebarView(selection: $selectedEntity)
                .environmentObject(manager)
        } detail: {
            if let selectedEntity = selectedEntity {
                ContentView(entity: selectedEntity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environmentObject(manager)
            } else {
                ContentUnavailableView("Select a model", systemImage: "tablecells.fill")
            }
        }
        .inspector(isPresented: $isInspectorOpen) {
            DetailView()
        }
        .fileImporter(
            isPresented: $isFileDialogOpen,
            allowedContentTypes: contentTypes,
            onCompletion: openFile
        )
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    self.isFileDialogOpen.toggle()
                }, label: {
                    if let filePath = manager.filePath {
                        Label {
                            Text(filePath.lastPathComponent).fontWeight(.bold)
                        } icon: {
                            Image(systemName:  "server.rack")
                        }
                        .labelStyle(.titleAndIcon)
                    } else {
                        Image(systemName: "folder")
                    }
                })
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    self.isInspectorOpen.toggle()
                }, label: {
                    Image(systemName: "sidebar.right")
                })
            }
        }
    }
    
    func openFile(file: Result<URL, any Error>) {
        switch file {
        case .success(let filePath):
            Task(priority: .userInitiated)  {
                do {
                    if filePath.startAccessingSecurityScopedResource() {
                        try await self.manager.connect(filePath: filePath)
                        
                        filePath.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    fatalError("Error fetching models: \(error)")
                }
            }
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }
}

#Preview {
    MainView()
}
