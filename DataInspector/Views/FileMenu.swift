//
//  FileMenu.swift
//  Data Inspector
//
//  Created by Axel Martinez on 20/11/24.
//

import UniformTypeIdentifiers
import SwiftUI

struct FileMenu: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var sqlManager: SQLManager
    
    @Binding var sidebarVisibility: NavigationSplitViewVisibility
    @Binding var isFileDialogOpen: Bool
    @Binding var isSimulatorsDialogOpen: Bool
    @Binding var selectedEntity: Entity?
    
    @State private var homeURL: URL?
    
    var body: some View {
        HStack(spacing: 5) {
            Menu {
                Button("Open File…") { self.isFileDialogOpen.toggle() }
                Button("Browse Simulators…") { self.isSimulatorsDialogOpen.toggle() }
            } label: {
                HStack {
                    if let appInfo = self.sqlManager.openAppInfo {
                        if let appIcon = self.sqlManager.openAppInfo?.icon {
                            Label {
                                Text("App Options")
                            } icon: {
                                Image(nsImage: appIcon)
                            }
                        }
                        
                        Text(appInfo.name)
                    } else if let fileURL = self.sqlManager.openFileURL {
                        Label {
                            Text("Foder Options")
                        } icon: {
                            Image(systemName: "folder")
                        }
                        
                        Text(fileURL.deletingLastPathComponent().lastPathComponent)
                    }
                }
                .padding(5)
            }
            .menuIndicator(.hidden)
            
            if let fileURL = self.sqlManager.openFileURL {
                Image(systemName: "chevron.forward")
                
                if self.sqlManager.openAppInfo?.fileURLs.count ?? 0 > 1 {
                    Menu {
                        if let fileURLs = self.sqlManager.openAppInfo?.fileURLs {
                            ForEach(fileURLs, id: \.self) { fileURL in
                                if fileURL != self.sqlManager.openFileURL {
                                    Button(fileURL.lastPathComponent) {
                                        loadFile(from: fileURL)
                                    }
                                }
                            }
                        }
                    } label: {
                        fileView(fileURL.lastPathComponent)
                    }
                    .menuIndicator(.hidden)
                } else {
                    fileView(fileURL.lastPathComponent)
                }
            }
        }
        .fileImporter(
            isPresented: $isFileDialogOpen,
            allowedContentTypes: URL.sqlLiteContentTypes,
            onCompletion: loadFile
        )
        .sheet(isPresented: $isSimulatorsDialogOpen, content: {
            SimulatorsView(sidebarVisibility: $sidebarVisibility)
                .frame(width:800, height: 600)
        })
        .onDisappear {
            self.homeURL?.stopAccessingSecurityScopedResource()
        }
    }
    
    @ViewBuilder
    private func fileView(_ fileName: String) -> some View {
        Image(systemName: "square.stack.3d.up")
        Text(fileName)
    }
    
    private func loadFile(from fileURL: URL) {
        Task(priority: .userInitiated) {
            if let homeBookmark = UserDefaults.standard.data(forKey: "homeBookmark") {
                var isHomeBookmarkInvalid = false
                
                self.homeURL = try URL(
                    resolvingBookmarkData: homeBookmark,
                    options: .withSecurityScope,
                    bookmarkDataIsStale: &isHomeBookmarkInvalid
                )
                
                if !isHomeBookmarkInvalid, let homeURL, homeURL.startAccessingSecurityScopedResource() {
                    do {
                        try await self.sqlManager.connect(
                            fileURL: fileURL,
                            appInfo: self.sqlManager.openAppInfo
                        )
                    } catch {
                        fatalError("Error loading file: \(error)")
                    }
                }
            }
        }
    }
    
    private func loadFile(result: Result<URL, any Error>) {
        switch result {
        case .success(let fileURL):
            Task(priority: .userInitiated)  {
                do {
                    if fileURL.startAccessingSecurityScopedResource() {
                        try await self.sqlManager.connect(fileURL: fileURL)
                        
                        self.sidebarVisibility = .all
                        
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    fatalError("Error loading file: \(error)")
                }
            }
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }
}
